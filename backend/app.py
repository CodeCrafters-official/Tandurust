from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_socketio import SocketIO, emit
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime, date
from dotenv import load_dotenv
import numpy as np
import requests as req_lib
import os
import json

load_dotenv()

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

# ================= DATABASE SETUP (NeonDB PostgreSQL) =================
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///tandurust.db')
app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'tandurust-secret')

db = SQLAlchemy(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# ================= LOAD TFLITE MODEL =================
interpreter = None
input_details = None
output_details = None

def _load_model():
    global interpreter, input_details, output_details
    model_path = "esi_model.tflite"
    if not os.path.exists(model_path):
        print("INFO: No esi_model.tflite found. Using rule-based triage.")
        return

    try:
        import tflite_runtime.interpreter as tflite
        interpreter = tflite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        print("TFLite runtime model loaded.")
        return
    except Exception:
        pass

    # Only try TF if numpy version is compatible
    try:
        np_version = tuple(int(x) for x in np.__version__.split('.')[:2])
        if np_version[0] >= 2:
            print("WARNING: NumPy 2.x detected, skipping TensorFlow (incompatible).")
            print("ML prediction will use rule-based fallback.")
            return
        import tensorflow as tf
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        print("TensorFlow model loaded.")
    except Exception as e:
        print(f"WARNING: Could not load ML model: {e}")
        print("ML prediction will use rule-based fallback.")

_load_model()


# ===============================================================
#                         MODELS
# ===============================================================

class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(150), unique=True, nullable=False)
    password_hash = db.Column(db.String(200), nullable=False)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)


class Patient(db.Model):
    __tablename__ = 'patients'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    username = db.Column(db.String(150), unique=True, nullable=False)
    password_hash = db.Column(db.String(200), nullable=False)
    abha_id = db.Column(db.String(50), unique=True)
    age = db.Column(db.Integer)
    gender = db.Column(db.String(20))
    phone = db.Column(db.String(20))
    address = db.Column(db.String(300))
    village = db.Column(db.String(100))
    blood_group = db.Column(db.String(10))
    chronic_conditions = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    visits = db.relationship('Visit', backref='patient', lazy=True)
    referrals = db.relationship('Referral', backref='patient', lazy=True)
    diagnostics = db.relationship('Diagnostic', backref='patient', lazy=True)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            'id': self.id, 'name': self.name, 'username': self.username,
            'abha_id': self.abha_id, 'age': self.age, 'gender': self.gender,
            'phone': self.phone, 'address': self.address, 'village': self.village,
            'blood_group': self.blood_group, 'chronic_conditions': self.chronic_conditions,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class Facility(db.Model):
    __tablename__ = 'facilities'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    type = db.Column(db.String(50), nullable=False)
    district = db.Column(db.String(100))
    address = db.Column(db.String(300))
    beds_total = db.Column(db.Integer, default=0)
    beds_available = db.Column(db.Integer, default=0)
    doctors_available = db.Column(db.Integer, default=0)
    has_lab = db.Column(db.Boolean, default=False)
    has_pharmacy = db.Column(db.Boolean, default=False)
    contact = db.Column(db.String(50))

    def to_dict(self):
        return {
            'id': self.id, 'name': self.name, 'type': self.type,
            'district': self.district, 'address': self.address,
            'beds_total': self.beds_total, 'beds_available': self.beds_available,
            'doctors_available': self.doctors_available, 'has_lab': self.has_lab,
            'has_pharmacy': self.has_pharmacy, 'contact': self.contact
        }


class Visit(db.Model):
    __tablename__ = 'visits'
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    facility_id = db.Column(db.Integer, db.ForeignKey('facilities.id'))
    doctor_name = db.Column(db.String(200))
    visit_date = db.Column(db.DateTime, default=datetime.utcnow)
    chief_complaint = db.Column(db.Text)
    diagnosis = db.Column(db.Text)
    prescription = db.Column(db.Text)
    vitals_json = db.Column(db.Text)
    notes = db.Column(db.Text)
    follow_up_date = db.Column(db.Date)

    def to_dict(self):
        return {
            'id': self.id, 'patient_id': self.patient_id,
            'facility_id': self.facility_id, 'doctor_name': self.doctor_name,
            'visit_date': self.visit_date.isoformat() if self.visit_date else None,
            'chief_complaint': self.chief_complaint, 'diagnosis': self.diagnosis,
            'prescription': self.prescription, 'vitals_json': self.vitals_json,
            'notes': self.notes,
            'follow_up_date': self.follow_up_date.isoformat() if self.follow_up_date else None
        }


class Referral(db.Model):
    __tablename__ = 'referrals'
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    from_facility_id = db.Column(db.Integer, db.ForeignKey('facilities.id'))
    to_facility_id = db.Column(db.Integer, db.ForeignKey('facilities.id'))
    reason = db.Column(db.Text)
    urgency = db.Column(db.String(20), default='routine')
    status = db.Column(db.String(20), default='pending')
    referred_date = db.Column(db.DateTime, default=datetime.utcnow)
    completed_date = db.Column(db.DateTime)
    notes = db.Column(db.Text)

    from_facility = db.relationship('Facility', foreign_keys=[from_facility_id])
    to_facility = db.relationship('Facility', foreign_keys=[to_facility_id])

    def to_dict(self):
        return {
            'id': self.id, 'patient_id': self.patient_id,
            'from_facility_id': self.from_facility_id, 'to_facility_id': self.to_facility_id,
            'from_facility_name': self.from_facility.name if self.from_facility else None,
            'to_facility_name': self.to_facility.name if self.to_facility else None,
            'reason': self.reason, 'urgency': self.urgency, 'status': self.status,
            'referred_date': self.referred_date.isoformat() if self.referred_date else None,
            'completed_date': self.completed_date.isoformat() if self.completed_date else None,
            'notes': self.notes
        }


class Diagnostic(db.Model):
    __tablename__ = 'diagnostics'
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    facility_id = db.Column(db.Integer, db.ForeignKey('facilities.id'))
    test_name = db.Column(db.String(200), nullable=False)
    ordered_by = db.Column(db.String(200))
    ordered_date = db.Column(db.DateTime, default=datetime.utcnow)
    status = db.Column(db.String(30), default='ordered')
    result = db.Column(db.Text)
    result_date = db.Column(db.DateTime)
    notes = db.Column(db.Text)

    def to_dict(self):
        return {
            'id': self.id, 'patient_id': self.patient_id,
            'facility_id': self.facility_id, 'test_name': self.test_name,
            'ordered_by': self.ordered_by,
            'ordered_date': self.ordered_date.isoformat() if self.ordered_date else None,
            'status': self.status, 'result': self.result,
            'result_date': self.result_date.isoformat() if self.result_date else None,
            'notes': self.notes
        }


class HighRiskPatient(db.Model):
    __tablename__ = 'high_risk_patients'
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    category = db.Column(db.String(30), nullable=False)
    condition_details = db.Column(db.Text)
    risk_level = db.Column(db.String(20), default='medium')
    last_followup_date = db.Column(db.Date)
    next_followup_date = db.Column(db.Date)
    asha_worker_name = db.Column(db.String(200))
    status = db.Column(db.String(20), default='active')
    notes = db.Column(db.Text)

    patient = db.relationship('Patient', backref='high_risk_records')

    def to_dict(self):
        return {
            'id': self.id, 'patient_id': self.patient_id,
            'patient_name': self.patient.name if self.patient else None,
            'category': self.category, 'condition_details': self.condition_details,
            'risk_level': self.risk_level,
            'last_followup_date': self.last_followup_date.isoformat() if self.last_followup_date else None,
            'next_followup_date': self.next_followup_date.isoformat() if self.next_followup_date else None,
            'asha_worker_name': self.asha_worker_name, 'status': self.status,
            'notes': self.notes
        }


class OPDQueue(db.Model):
    __tablename__ = 'opd_queue'
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    facility_id = db.Column(db.Integer, db.ForeignKey('facilities.id'))
    token_number = db.Column(db.Integer)
    department = db.Column(db.String(100))
    doctor_name = db.Column(db.String(200))
    status = db.Column(db.String(30), default='waiting')
    estimated_wait_minutes = db.Column(db.Integer, default=0)
    check_in_time = db.Column(db.DateTime, default=datetime.utcnow)
    consultation_start_time = db.Column(db.DateTime)

    patient = db.relationship('Patient', backref='queue_entries')

    def to_dict(self):
        return {
            'id': self.id, 'patient_id': self.patient_id,
            'patient_name': self.patient.name if self.patient else None,
            'facility_id': self.facility_id, 'token_number': self.token_number,
            'department': self.department, 'doctor_name': self.doctor_name,
            'status': self.status, 'estimated_wait_minutes': self.estimated_wait_minutes,
            'check_in_time': self.check_in_time.isoformat() if self.check_in_time else None,
            'consultation_start_time': self.consultation_start_time.isoformat() if self.consultation_start_time else None
        }


class ASHAWorker(db.Model):
    __tablename__ = 'asha_workers'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    username = db.Column(db.String(150), unique=True, nullable=False)
    password_hash = db.Column(db.String(200), nullable=False)
    phone = db.Column(db.String(20))
    village = db.Column(db.String(100))
    assigned_patients_count = db.Column(db.Integer, default=0)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            'id': self.id, 'name': self.name, 'username': self.username,
            'phone': self.phone, 'village': self.village,
            'assigned_patients_count': self.assigned_patients_count
        }


class Doctor(db.Model):
    __tablename__ = 'doctors'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    username = db.Column(db.String(150), unique=True, nullable=False)
    password_hash = db.Column(db.String(200), nullable=False)
    phone = db.Column(db.String(20))
    specialty = db.Column(db.String(100))
    facility_id = db.Column(db.Integer, db.ForeignKey('facilities.id'))
    experience_years = db.Column(db.Integer)
    is_available = db.Column(db.Boolean, default=True)

    facility = db.relationship('Facility', backref='doctors')

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            'id': self.id, 'name': self.name, 'username': self.username,
            'phone': self.phone, 'specialty': self.specialty,
            'facility_id': self.facility_id, 'experience_years': self.experience_years,
            'is_available': self.is_available
        }


class Teleconsultation(db.Model):
    __tablename__ = 'teleconsultations'
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    doctor_name = db.Column(db.String(200))
    facility_id = db.Column(db.Integer, db.ForeignKey('facilities.id'))
    scheduled_time = db.Column(db.DateTime)
    status = db.Column(db.String(30), default='scheduled')
    call_type = db.Column(db.String(20), default='video')
    room_id = db.Column(db.String(100))
    notes = db.Column(db.Text)
    prescription = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    patient = db.relationship('Patient', backref='teleconsultations')

    def to_dict(self):
        return {
            'id': self.id, 'patient_id': self.patient_id,
            'patient_name': self.patient.name if self.patient else None,
            'doctor_name': self.doctor_name, 'facility_id': self.facility_id,
            'scheduled_time': self.scheduled_time.isoformat() if self.scheduled_time else None,
            'status': self.status, 'call_type': self.call_type,
            'room_id': self.room_id,
            'notes': self.notes, 'prescription': self.prescription,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class Notification(db.Model):
    __tablename__ = 'notifications'
    id = db.Column(db.Integer, primary_key=True)
    user_type = db.Column(db.String(20))
    user_id = db.Column(db.Integer)
    title = db.Column(db.String(200))
    message = db.Column(db.Text)
    type = db.Column(db.String(30))
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id, 'user_type': self.user_type, 'user_id': self.user_id,
            'title': self.title, 'message': self.message, 'type': self.type,
            'is_read': self.is_read,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


# ===============================================================
#                         ROUTES
# ===============================================================

@app.route("/")
def home():
    return jsonify({"status": "running", "database": "NeonDB PostgreSQL" if "neon" in DATABASE_URL else "SQLite (fallback)"})


# ================= AUTH ROUTES =================
@app.route('/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'error': 'Username and password required'}), 400
    if User.query.filter_by(username=username).first():
        return jsonify({'error': 'Username already exists'}), 400
    user = User(username=username)
    user.set_password(password)
    db.session.add(user)
    db.session.commit()
    return jsonify({'message': 'User registered successfully'}), 201


@app.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'error': 'Username and password required'}), 400
    user = User.query.filter_by(username=username).first()
    if user and user.check_password(password):
        return jsonify({'message': 'Login successful'}), 200
    return jsonify({'error': 'Invalid credentials'}), 401


# ================= PATIENT ROUTES =================
@app.route('/patients/register', methods=['POST'])
def register_patient():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    name = data.get('name', data.get('username'))
    if not username or not password:
        return jsonify({'error': 'Username and password required'}), 400
    if Patient.query.filter_by(username=username).first():
        return jsonify({'error': 'Username already exists'}), 400
    patient = Patient(
        name=name, username=username,
        abha_id=data.get('abha_id'), age=data.get('age'),
        gender=data.get('gender'), phone=data.get('phone'),
        address=data.get('address'), village=data.get('village'),
        blood_group=data.get('blood_group'),
        chronic_conditions=data.get('chronic_conditions')
    )
    patient.set_password(password)
    db.session.add(patient)
    db.session.commit()
    return jsonify({'message': 'Patient registered successfully', 'patient': patient.to_dict()}), 201


@app.route('/patients/signup', methods=['POST'])
def signup_patient():
    return register_patient()


@app.route('/patients/login', methods=['POST'])
def login_patient():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'error': 'Username and password required'}), 400
    patient = Patient.query.filter_by(username=username).first()
    if patient and patient.check_password(password):
        return jsonify({'message': 'Login successful', 'patient': patient.to_dict()}), 200
    return jsonify({'error': 'Invalid credentials'}), 401


@app.route('/patients', methods=['GET'])
def get_patients():
    patients = Patient.query.all()
    return jsonify([p.to_dict() for p in patients])


@app.route('/patients/<int:patient_id>', methods=['GET'])
def get_patient(patient_id):
    patient = Patient.query.get_or_404(patient_id)
    return jsonify(patient.to_dict())


@app.route('/patients/<int:patient_id>', methods=['PUT'])
def update_patient(patient_id):
    patient = Patient.query.get_or_404(patient_id)
    data = request.json
    for field in ['name', 'age', 'gender', 'phone', 'address', 'village', 'blood_group', 'chronic_conditions', 'abha_id']:
        if field in data:
            setattr(patient, field, data[field])
    db.session.commit()
    return jsonify({'message': 'Patient updated', 'patient': patient.to_dict()})


# ================= FACILITY ROUTES =================
@app.route('/facilities', methods=['GET'])
def get_facilities():
    facilities = Facility.query.all()
    return jsonify([f.to_dict() for f in facilities])


@app.route('/facilities', methods=['POST'])
def create_facility():
    data = request.json
    facility = Facility(
        name=data['name'], type=data['type'],
        district=data.get('district'), address=data.get('address'),
        beds_total=data.get('beds_total', 0), beds_available=data.get('beds_available', 0),
        doctors_available=data.get('doctors_available', 0),
        has_lab=data.get('has_lab', False), has_pharmacy=data.get('has_pharmacy', False),
        contact=data.get('contact')
    )
    db.session.add(facility)
    db.session.commit()
    return jsonify({'message': 'Facility created', 'facility': facility.to_dict()}), 201


@app.route('/facilities/<int:facility_id>', methods=['GET'])
def get_facility(facility_id):
    facility = Facility.query.get_or_404(facility_id)
    return jsonify(facility.to_dict())


@app.route('/facilities/<int:facility_id>', methods=['PUT'])
def update_facility(facility_id):
    facility = Facility.query.get_or_404(facility_id)
    data = request.json
    for field in ['name', 'type', 'district', 'address', 'beds_total', 'beds_available', 'doctors_available', 'has_lab', 'has_pharmacy', 'contact']:
        if field in data:
            setattr(facility, field, data[field])
    db.session.commit()
    return jsonify({'message': 'Facility updated', 'facility': facility.to_dict()})


@app.route('/facilities/<int:facility_id>/dashboard', methods=['GET'])
def facility_dashboard(facility_id):
    facility = Facility.query.get_or_404(facility_id)
    today = date.today()
    today_start = datetime(today.year, today.month, today.day)

    stats = {
        'visits_today': Visit.query.filter(Visit.facility_id == facility_id, Visit.visit_date >= today_start).count(),
        'pending_referrals_in': Referral.query.filter_by(to_facility_id=facility_id, status='pending').count(),
        'pending_referrals_out': Referral.query.filter_by(from_facility_id=facility_id, status='pending').count(),
        'queue_waiting': OPDQueue.query.filter_by(facility_id=facility_id, status='waiting').count(),
        'pending_diagnostics': Diagnostic.query.filter(Diagnostic.facility_id == facility_id, Diagnostic.status != 'completed').count(),
        'high_risk_patients': db.session.query(HighRiskPatient).join(Visit, HighRiskPatient.patient_id == Visit.patient_id).filter(Visit.facility_id == facility_id, HighRiskPatient.status == 'active').count()
    }
    return jsonify({'facility': facility.to_dict(), 'stats': stats})


# ================= VISIT / EHR ROUTES =================
@app.route('/visits', methods=['POST'])
def create_visit():
    data = request.json
    visit = Visit(
        patient_id=data['patient_id'], facility_id=data.get('facility_id'),
        doctor_name=data.get('doctor_name'), chief_complaint=data.get('chief_complaint'),
        diagnosis=data.get('diagnosis'), prescription=data.get('prescription'),
        vitals_json=data.get('vitals_json'), notes=data.get('notes'),
        follow_up_date=datetime.strptime(data['follow_up_date'], '%Y-%m-%d').date() if data.get('follow_up_date') else None
    )
    db.session.add(visit)
    db.session.commit()
    return jsonify({'message': 'Visit recorded', 'visit': visit.to_dict()}), 201


@app.route('/visits', methods=['GET'])
def get_all_visits():
    visits = Visit.query.order_by(Visit.visit_date.desc()).all()
    return jsonify([v.to_dict() for v in visits])


@app.route('/patients/<int:patient_id>/visits', methods=['GET'])
def get_patient_visits(patient_id):
    visits = Visit.query.filter_by(patient_id=patient_id).order_by(Visit.visit_date.desc()).all()
    return jsonify([v.to_dict() for v in visits])


@app.route('/visits/<int:visit_id>', methods=['GET'])
def get_visit(visit_id):
    visit = Visit.query.get_or_404(visit_id)
    return jsonify(visit.to_dict())


@app.route('/visits/<int:visit_id>', methods=['PUT'])
def update_visit(visit_id):
    visit = Visit.query.get_or_404(visit_id)
    data = request.json
    for field in ['doctor_name', 'chief_complaint', 'diagnosis', 'prescription', 'vitals_json', 'notes']:
        if field in data:
            setattr(visit, field, data[field])
    if 'follow_up_date' in data:
        visit.follow_up_date = datetime.strptime(data['follow_up_date'], '%Y-%m-%d').date() if data['follow_up_date'] else None
    db.session.commit()
    return jsonify({'message': 'Visit updated', 'visit': visit.to_dict()})


# ================= REFERRAL ROUTES =================
@app.route('/referrals', methods=['POST'])
def create_referral():
    data = request.json
    referral = Referral(
        patient_id=data['patient_id'],
        from_facility_id=data.get('from_facility_id'),
        to_facility_id=data.get('to_facility_id'),
        reason=data.get('reason'), urgency=data.get('urgency', 'routine'),
        notes=data.get('notes')
    )
    db.session.add(referral)
    db.session.commit()

    # Real-time notification
    _send_notification('facility', data.get('to_facility_id'),
                       'New Referral', f"Patient referred: {referral.reason}", 'referral')

    return jsonify({'message': 'Referral created', 'referral': referral.to_dict()}), 201


@app.route('/referrals', methods=['GET'])
def get_all_referrals():
    referrals = Referral.query.order_by(Referral.referred_date.desc()).all()
    return jsonify([r.to_dict() for r in referrals])


@app.route('/patients/<int:patient_id>/referrals', methods=['GET'])
def get_patient_referrals(patient_id):
    referrals = Referral.query.filter_by(patient_id=patient_id).order_by(Referral.referred_date.desc()).all()
    return jsonify([r.to_dict() for r in referrals])


@app.route('/referrals/<int:referral_id>', methods=['GET'])
def get_referral(referral_id):
    referral = Referral.query.get_or_404(referral_id)
    return jsonify(referral.to_dict())


@app.route('/referrals/<int:referral_id>/status', methods=['PUT'])
def update_referral_status(referral_id):
    referral = Referral.query.get_or_404(referral_id)
    data = request.json
    new_status = data.get('status')
    if new_status not in ['pending', 'accepted', 'in_transit', 'completed', 'cancelled']:
        return jsonify({'error': 'Invalid status'}), 400
    referral.status = new_status
    if new_status == 'completed':
        referral.completed_date = datetime.utcnow()
    if 'notes' in data:
        referral.notes = data['notes']
    db.session.commit()

    # Notify patient about referral update
    _send_notification('patient', referral.patient_id,
                       'Referral Updated', f"Your referral status: {new_status}", 'referral')

    return jsonify({'message': 'Referral status updated', 'referral': referral.to_dict()})


# ================= DIAGNOSTIC ROUTES =================
@app.route('/diagnostics', methods=['POST'])
def create_diagnostic():
    data = request.json
    diagnostic = Diagnostic(
        patient_id=data['patient_id'], facility_id=data.get('facility_id'),
        test_name=data['test_name'], ordered_by=data.get('ordered_by'),
        notes=data.get('notes')
    )
    db.session.add(diagnostic)
    db.session.commit()
    return jsonify({'message': 'Diagnostic ordered', 'diagnostic': diagnostic.to_dict()}), 201


@app.route('/diagnostics', methods=['GET'])
def get_all_diagnostics():
    diagnostics = Diagnostic.query.order_by(Diagnostic.ordered_date.desc()).all()
    return jsonify([d.to_dict() for d in diagnostics])


@app.route('/patients/<int:patient_id>/diagnostics', methods=['GET'])
def get_patient_diagnostics(patient_id):
    diagnostics = Diagnostic.query.filter_by(patient_id=patient_id).order_by(Diagnostic.ordered_date.desc()).all()
    return jsonify([d.to_dict() for d in diagnostics])


@app.route('/diagnostics/<int:diagnostic_id>', methods=['GET'])
def get_diagnostic(diagnostic_id):
    diagnostic = Diagnostic.query.get_or_404(diagnostic_id)
    return jsonify(diagnostic.to_dict())


@app.route('/diagnostics/<int:diagnostic_id>/status', methods=['PUT'])
def update_diagnostic_status(diagnostic_id):
    diagnostic = Diagnostic.query.get_or_404(diagnostic_id)
    data = request.json
    new_status = data.get('status')
    if new_status not in ['ordered', 'sample_collected', 'processing', 'completed']:
        return jsonify({'error': 'Invalid status'}), 400
    diagnostic.status = new_status
    if new_status == 'completed':
        diagnostic.result = data.get('result')
        diagnostic.result_date = datetime.utcnow()
    if 'notes' in data:
        diagnostic.notes = data['notes']
    db.session.commit()

    _send_notification('patient', diagnostic.patient_id,
                       'Lab Result Ready', f"Your {diagnostic.test_name} result is ready", 'diagnostic')

    return jsonify({'message': 'Diagnostic updated', 'diagnostic': diagnostic.to_dict()})


# ================= HIGH-RISK PATIENT ROUTES =================
@app.route('/high-risk', methods=['POST'])
def create_high_risk():
    data = request.json
    hr = HighRiskPatient(
        patient_id=data['patient_id'], category=data['category'],
        condition_details=data.get('condition_details'),
        risk_level=data.get('risk_level', 'medium'),
        next_followup_date=datetime.strptime(data['next_followup_date'], '%Y-%m-%d').date() if data.get('next_followup_date') else None,
        asha_worker_name=data.get('asha_worker_name'), notes=data.get('notes')
    )
    db.session.add(hr)
    db.session.commit()
    return jsonify({'message': 'High-risk record created', 'record': hr.to_dict()}), 201


@app.route('/high-risk', methods=['GET'])
def get_all_high_risk():
    records = HighRiskPatient.query.filter_by(status='active').all()
    return jsonify([r.to_dict() for r in records])


@app.route('/high-risk/<int:record_id>', methods=['GET'])
def get_high_risk(record_id):
    record = HighRiskPatient.query.get_or_404(record_id)
    return jsonify(record.to_dict())


@app.route('/high-risk/<int:record_id>', methods=['PUT'])
def update_high_risk(record_id):
    record = HighRiskPatient.query.get_or_404(record_id)
    data = request.json
    for field in ['category', 'condition_details', 'risk_level', 'asha_worker_name', 'status', 'notes']:
        if field in data:
            setattr(record, field, data[field])
    if 'last_followup_date' in data:
        record.last_followup_date = datetime.strptime(data['last_followup_date'], '%Y-%m-%d').date() if data['last_followup_date'] else None
    if 'next_followup_date' in data:
        record.next_followup_date = datetime.strptime(data['next_followup_date'], '%Y-%m-%d').date() if data['next_followup_date'] else None
    db.session.commit()
    return jsonify({'message': 'High-risk record updated', 'record': record.to_dict()})


@app.route('/high-risk/overdue', methods=['GET'])
def get_overdue_followups():
    today = date.today()
    overdue = HighRiskPatient.query.filter(
        HighRiskPatient.status == 'active',
        HighRiskPatient.next_followup_date < today
    ).all()
    return jsonify([r.to_dict() for r in overdue])


# ================= OPD QUEUE ROUTES =================
@app.route('/queue', methods=['GET'])
def get_queue():
    facility_id = request.args.get('facility_id')
    query = OPDQueue.query.filter_by(status='waiting')
    if facility_id:
        query = query.filter_by(facility_id=int(facility_id))
    queue = query.order_by(OPDQueue.token_number).all()
    return jsonify([q.to_dict() for q in queue])


@app.route('/queue/check-in', methods=['POST'])
def queue_check_in():
    data = request.json
    facility_id = data.get('facility_id')
    department = data.get('department', 'General OPD')

    last_token = OPDQueue.query.filter_by(facility_id=facility_id).order_by(OPDQueue.token_number.desc()).first()
    next_token = (last_token.token_number + 1) if last_token else 1

    waiting_count = OPDQueue.query.filter_by(facility_id=facility_id, status='waiting', department=department).count()
    estimated_wait = waiting_count * 15

    entry = OPDQueue(
        patient_id=data['patient_id'], facility_id=facility_id,
        token_number=next_token, department=department,
        doctor_name=data.get('doctor_name'), estimated_wait_minutes=estimated_wait
    )
    db.session.add(entry)
    db.session.commit()

    # Real-time: broadcast queue update
    socketio.emit('queue_update', {
        'facility_id': facility_id, 'department': department,
        'waiting_count': waiting_count + 1, 'latest_token': next_token
    }, namespace='/queue')

    return jsonify({'message': 'Checked in', 'queue': entry.to_dict()}), 201


@app.route('/queue/<int:queue_id>/status', methods=['PUT'])
def update_queue_status(queue_id):
    entry = OPDQueue.query.get_or_404(queue_id)
    data = request.json
    new_status = data.get('status')
    if new_status not in ['waiting', 'in_consultation', 'completed']:
        return jsonify({'error': 'Invalid status'}), 400

    entry.status = new_status
    if new_status == 'in_consultation':
        entry.consultation_start_time = datetime.utcnow()

    db.session.commit()

    if new_status == 'in_consultation':
        remaining = OPDQueue.query.filter(
            OPDQueue.facility_id == entry.facility_id,
            OPDQueue.status == 'waiting',
            OPDQueue.department == entry.department
        ).all()
        for i, q in enumerate(remaining):
            q.estimated_wait_minutes = (i + 1) * 15
        db.session.commit()

        # Real-time notification to next patient
        socketio.emit('queue_update', {
            'facility_id': entry.facility_id, 'department': entry.department,
            'now_serving': entry.token_number, 'waiting_count': len(remaining)
        }, namespace='/queue')

    return jsonify({'message': 'Queue status updated', 'queue': entry.to_dict()})


# ================= ASHA WORKER ROUTES =================
@app.route('/asha/register', methods=['POST'])
def register_asha():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    name = data.get('name')
    if not username or not password or not name:
        return jsonify({'error': 'Name, username and password required'}), 400
    if ASHAWorker.query.filter_by(username=username).first():
        return jsonify({'error': 'Username already exists'}), 400
    worker = ASHAWorker(name=name, username=username, phone=data.get('phone'), village=data.get('village'))
    worker.set_password(password)
    db.session.add(worker)
    db.session.commit()
    return jsonify({'message': 'ASHA worker registered', 'worker': worker.to_dict()}), 201


@app.route('/asha/login', methods=['POST'])
def login_asha():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'error': 'Username and password required'}), 400
    worker = ASHAWorker.query.filter_by(username=username).first()
    if worker and worker.check_password(password):
        return jsonify({'message': 'Login successful', 'worker': worker.to_dict()}), 200
    return jsonify({'error': 'Invalid credentials'}), 401


@app.route('/asha/<int:worker_id>/patients', methods=['GET'])
def get_asha_patients(worker_id):
    worker = ASHAWorker.query.get_or_404(worker_id)
    high_risk = HighRiskPatient.query.filter_by(asha_worker_name=worker.name, status='active').all()
    return jsonify({'worker': worker.to_dict(), 'patients': [r.to_dict() for r in high_risk]})


# ================= DOCTOR ROUTES =================
@app.route('/doctors/register', methods=['POST'])
def register_doctor():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    name = data.get('name')
    if not username or not password or not name:
        return jsonify({'error': 'Name, username and password required'}), 400
    if Doctor.query.filter_by(username=username).first():
        return jsonify({'error': 'Username already exists'}), 400
    doctor = Doctor(
        name=name, username=username, phone=data.get('phone'),
        specialty=data.get('specialty'), facility_id=data.get('facility_id'),
        experience_years=data.get('experience_years')
    )
    doctor.set_password(password)
    db.session.add(doctor)
    db.session.commit()
    return jsonify({'message': 'Doctor registered successfully', 'doctor': doctor.to_dict()}), 201


@app.route('/doctors/login', methods=['POST'])
def login_doctor():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'error': 'Username and password required'}), 400
    doctor = Doctor.query.filter_by(username=username).first()
    if doctor and doctor.check_password(password):
        return jsonify({'message': 'Login successful', 'doctor': doctor.to_dict()}), 200
    return jsonify({'error': 'Invalid credentials'}), 401


@app.route('/doctors', methods=['GET'])
def get_doctors():
    doctors = Doctor.query.all()
    return jsonify([d.to_dict() for d in doctors])


@app.route('/doctors/<int:doctor_id>', methods=['GET'])
def get_doctor(doctor_id):
    doctor = Doctor.query.get_or_404(doctor_id)
    return jsonify(doctor.to_dict())


@app.route('/doctors/<int:doctor_id>/availability', methods=['PUT'])
def toggle_doctor_availability(doctor_id):
    doctor = Doctor.query.get_or_404(doctor_id)
    data = request.json
    doctor.is_available = data.get('is_available', not doctor.is_available)
    db.session.commit()
    return jsonify({'message': 'Availability updated', 'doctor': doctor.to_dict()})


# ================= TELECONSULTATION ROUTES =================
@app.route('/teleconsultations', methods=['POST'])
def create_teleconsultation():
    data = request.json
    import hashlib
    pid = str(data.get('patient_id', '0'))
    ts = str(datetime.utcnow().timestamp())
    room_id = "tandurust-" + hashlib.md5((pid + "-" + ts).encode()).hexdigest()[:12]

    tc = Teleconsultation(
        patient_id=data['patient_id'], doctor_name=data.get('doctor_name'),
        facility_id=data.get('facility_id'),
        scheduled_time=datetime.strptime(data['scheduled_time'], '%Y-%m-%dT%H:%M') if data.get('scheduled_time') else None,
        call_type=data.get('call_type', 'video'), room_id=room_id,
        notes=data.get('notes')
    )
    db.session.add(tc)
    db.session.commit()

    _send_notification('patient', data['patient_id'],
                       'Teleconsultation Scheduled',
                       f"Video call with {data.get('doctor_name')} scheduled. Room: {room_id}",
                       'teleconsultation')

    return jsonify({'message': 'Teleconsultation scheduled', 'teleconsultation': tc.to_dict()}), 201


@app.route('/teleconsultations', methods=['GET'])
def get_teleconsultations():
    tcs = Teleconsultation.query.order_by(Teleconsultation.scheduled_time.desc()).all()
    return jsonify([t.to_dict() for t in tcs])


@app.route('/patients/<int:patient_id>/teleconsultations', methods=['GET'])
def get_patient_teleconsultations(patient_id):
    tcs = Teleconsultation.query.filter_by(patient_id=patient_id).order_by(Teleconsultation.scheduled_time.desc()).all()
    return jsonify([t.to_dict() for t in tcs])


@app.route('/teleconsultations/<int:tc_id>/status', methods=['PUT'])
def update_teleconsultation_status(tc_id):
    tc = Teleconsultation.query.get_or_404(tc_id)
    data = request.json
    new_status = data.get('status')
    if new_status not in ['scheduled', 'in_progress', 'completed', 'cancelled']:
        return jsonify({'error': 'Invalid status'}), 400
    tc.status = new_status
    if 'notes' in data: tc.notes = data['notes']
    if 'prescription' in data: tc.prescription = data['prescription']
    db.session.commit()
    return jsonify({'message': 'Teleconsultation updated', 'teleconsultation': tc.to_dict()})


@app.route('/teleconsultations/<int:tc_id>/join', methods=['GET'])
def join_teleconsultation(tc_id):
    tc = Teleconsultation.query.get_or_404(tc_id)
    jitsi_url = f"https://meet.jit.si/{tc.room_id}"
    return jsonify({
        'room_id': tc.room_id,
        'jitsi_url': jitsi_url,
        'doctor_name': tc.doctor_name,
        'patient_name': tc.patient.name if tc.patient else None
    })


# ================= NOTIFICATION ROUTES =================
@app.route('/notifications/<string:user_type>/<int:user_id>', methods=['GET'])
def get_notifications(user_type, user_id):
    notifs = Notification.query.filter_by(user_type=user_type, user_id=user_id).order_by(Notification.created_at.desc()).limit(50).all()
    return jsonify([n.to_dict() for n in notifs])


@app.route('/notifications/<int:notif_id>/read', methods=['PUT'])
def mark_notification_read(notif_id):
    notif = Notification.query.get_or_404(notif_id)
    notif.is_read = True
    db.session.commit()
    return jsonify({'message': 'Marked as read'})


def _send_notification(user_type, user_id, title, message, notif_type):
    notif = Notification(user_type=user_type, user_id=user_id, title=title, message=message, type=notif_type)
    db.session.add(notif)
    db.session.commit()
    socketio.emit('notification', notif.to_dict(), namespace='/notifications')


# ================= ML PREDICTION (ESI TRIAGE) =================
@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.json
        features = data.get("features")
        if not features:
            return jsonify({"error": "No features provided"}), 400

        triage_map = {
            0: {"esi_level": 5, "label": "Non-Urgent"},
            1: {"esi_level": 4, "label": "Less Urgent"},
            2: {"esi_level": 3, "label": "Urgent"},
            3: {"esi_level": 2, "label": "Emergency"},
            4: {"esi_level": 1, "label": "Immediate"}
        }

        if interpreter is not None:
            input_data = np.array([features], dtype=np.float32)
            interpreter.set_tensor(input_details[0]["index"], input_data)
            interpreter.invoke()
            output = interpreter.get_tensor(output_details[0]["index"])[0]
            predicted_class = int(np.argmax(output))
            confidence = float(np.max(output))
        else:
            # Rule-based fallback when model unavailable
            predicted_class = _rule_based_triage(features)
            confidence = 0.85

        result = triage_map[predicted_class]
        return jsonify({"esi_level": result["esi_level"], "triage_label": result["label"], "confidence": confidence})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


def _rule_based_triage(features):
    """Rule-based ESI triage when ML model is unavailable."""
    if len(features) < 7:
        return 2
    hr = features[0] if len(features) > 0 else 80
    systolic = features[1] if len(features) > 1 else 120
    spo2 = features[3] if len(features) > 3 else 98
    unconscious = features[9] if len(features) > 9 else 0
    pain = features[8] if len(features) > 8 else 0

    if unconscious == 1 or spo2 < 90 or hr > 150 or systolic < 70:
        return 4  # ESI 1 - Immediate
    if spo2 < 93 or hr > 130 or systolic < 80 or pain > 80:
        return 3  # ESI 2 - Emergency
    if hr > 110 or systolic > 180 or pain > 60:
        return 2  # ESI 3 - Urgent
    if hr > 100 or systolic > 150 or pain > 30:
        return 1  # ESI 4 - Less Urgent
    return 0  # ESI 5 - Non-Urgent


@app.route("/triage-multiple", methods=["POST"])
def triage_multiple():
    try:
        data = request.json
        patients = data.get("patients")
        if not patients:
            return jsonify({"error": "No patient data provided"}), 400

        triage_map = {
            0: {"esi_level": 5, "label": "Non-Urgent"},
            1: {"esi_level": 4, "label": "Less Urgent"},
            2: {"esi_level": 3, "label": "Urgent"},
            3: {"esi_level": 2, "label": "Emergency"},
            4: {"esi_level": 1, "label": "Immediate"}
        }

        results = []
        for patient in patients:
            name = patient["name"]
            features = patient["features"]

            if interpreter is not None:
                input_data = np.array([features], dtype=np.float32)
                interpreter.set_tensor(input_details[0]["index"], input_data)
                interpreter.invoke()
                output = interpreter.get_tensor(output_details[0]["index"])[0]
                predicted_class = int(np.argmax(output))
                confidence = float(np.max(output))
            else:
                predicted_class = _rule_based_triage(features)
                confidence = 0.85

            result = triage_map[predicted_class]
            results.append({"name": name, "esi_level": result["esi_level"], "triage_label": result["label"], "confidence": confidence})

        results.sort(key=lambda x: x["esi_level"])
        return jsonify({"most_critical_patient": results[0], "all_patients_sorted": results})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ================= WEBSOCKET EVENTS =================
@socketio.on('connect', namespace='/queue')
def handle_queue_connect():
    emit('connected', {'message': 'Connected to queue updates'})


@socketio.on('connect', namespace='/notifications')
def handle_notif_connect():
    emit('connected', {'message': 'Connected to notifications'})


@socketio.on('join_room', namespace='/teleconsult')
def handle_join_teleconsult(data):
    room_id = data.get('room_id')
    emit('user_joined', {'room_id': room_id, 'user': data.get('user_name')}, broadcast=True)


# ===============================================================
#                     SEED DATA
# ===============================================================

def seed_facilities():
    if Facility.query.count() == 0:
        facilities = [
            Facility(name="Ambegaon Sub-Centre", type="Sub-Centre", district="Pune",
                     address="Ambegaon, Pune District", beds_total=5, beds_available=3,
                     doctors_available=1, has_lab=False, has_pharmacy=True, contact="020-26000001"),
            Facility(name="Junnar Primary Health Centre", type="PHC", district="Pune",
                     address="Junnar, Pune District", beds_total=15, beds_available=8,
                     doctors_available=3, has_lab=True, has_pharmacy=True, contact="020-26000002"),
            Facility(name="Shirur Community Health Centre", type="CHC", district="Pune",
                     address="Shirur, Pune District", beds_total=30, beds_available=12,
                     doctors_available=6, has_lab=True, has_pharmacy=True, contact="020-26000003"),
            Facility(name="Sassoon General Hospital", type="District Hospital", district="Pune",
                     address="Sassoon Road, Pune", beds_total=200, beds_available=45,
                     doctors_available=40, has_lab=True, has_pharmacy=True, contact="020-26000004"),
            Facility(name="Dahanu Sub-Centre", type="Sub-Centre", district="Palghar",
                     address="Dahanu, Palghar District", beds_total=4, beds_available=2,
                     doctors_available=1, has_lab=False, has_pharmacy=False, contact="02528-220001"),
            Facility(name="Vikramgad PHC", type="PHC", district="Palghar",
                     address="Vikramgad, Palghar District", beds_total=12, beds_available=6,
                     doctors_available=2, has_lab=True, has_pharmacy=True, contact="02528-220002"),
        ]
        db.session.add_all(facilities)
        db.session.commit()
        print("Seeded 6 facilities.")


def seed_asha_workers():
    if ASHAWorker.query.count() == 0:
        workers = [
            {"name": "Sunita Pawar", "username": "sunita", "password": "asha123", "phone": "9876543210", "village": "Ambegaon"},
            {"name": "Kavita Jadhav", "username": "kavita", "password": "asha123", "phone": "9876543211", "village": "Junnar"},
            {"name": "Manisha Shinde", "username": "manisha", "password": "asha123", "phone": "9876543212", "village": "Dahanu"},
        ]
        for w in workers:
            worker = ASHAWorker(name=w['name'], username=w['username'], phone=w['phone'], village=w['village'])
            worker.set_password(w['password'])
            db.session.add(worker)
        db.session.commit()
        print("Seeded 3 ASHA workers.")


def seed_patients():
    if Patient.query.count() == 0:
        patients_data = [
            {"name": "Lakshmi Devi", "username": "lakshmi", "password": "patient123",
             "abha_id": "ABHA-2024-78432", "age": 34, "gender": "Female",
             "phone": "9876543220", "village": "Koregaon", "blood_group": "B+",
             "chronic_conditions": "Gestational Diabetes,Anemia"},
            {"name": "Raju Patil", "username": "raju", "password": "patient123",
             "abha_id": "ABHA-2024-78433", "age": 45, "gender": "Male",
             "phone": "9876543221", "village": "Ambegaon", "blood_group": "O+",
             "chronic_conditions": "Hypertension"},
            {"name": "Meena Jadhav", "username": "meena", "password": "patient123",
             "abha_id": "ABHA-2024-78434", "age": 28, "gender": "Female",
             "phone": "9876543222", "village": "Junnar", "blood_group": "A+",
             "chronic_conditions": ""},
            {"name": "Shankar Gaikwad", "username": "shankar", "password": "patient123",
             "abha_id": "ABHA-2024-78435", "age": 55, "gender": "Male",
             "phone": "9876543223", "village": "Shirur", "blood_group": "AB+",
             "chronic_conditions": "Diabetes,COPD"},
        ]
        for p in patients_data:
            patient = Patient(
                name=p['name'], username=p['username'], abha_id=p['abha_id'],
                age=p['age'], gender=p['gender'], phone=p['phone'],
                village=p['village'], blood_group=p['blood_group'],
                chronic_conditions=p['chronic_conditions']
            )
            patient.set_password(p['password'])
            db.session.add(patient)
        db.session.commit()
        print("Seeded 4 patients.")


def seed_doctors():
    if Doctor.query.count() == 0:
        doctors_data = [
            {"name": "Dr. Priya Kulkarni", "username": "priya", "password": "doc123",
             "phone": "9876543230", "specialty": "Obstetrics", "experience_years": 12},
            {"name": "Dr. Anil Patil", "username": "anil", "password": "doc123",
             "phone": "9876543231", "specialty": "General Medicine", "experience_years": 8},
            {"name": "Dr. Sneha Iyer", "username": "sneha", "password": "doc123",
             "phone": "9876543232", "specialty": "Pediatrics", "experience_years": 5},
        ]
        for d in doctors_data:
            doctor = Doctor(
                name=d['name'], username=d['username'], phone=d['phone'],
                specialty=d['specialty'], experience_years=d['experience_years'], is_available=True
            )
            doctor.set_password(d['password'])
            db.session.add(doctor)
        db.session.commit()
        print("Seeded 3 doctors.")


def seed_high_risk():
    if HighRiskPatient.query.count() == 0:
        patients = Patient.query.all()
        if len(patients) >= 4:
            records = [
                HighRiskPatient(patient_id=patients[0].id, category='maternal',
                    condition_details='Gestational Diabetes + Anemia (7th month)',
                    risk_level='high', asha_worker_name='Sunita Pawar',
                    next_followup_date=date(2026, 9, 3), status='active',
                    notes='Monitor blood sugar and hemoglobin levels'),
                HighRiskPatient(patient_id=patients[3].id, category='chronic',
                    condition_details='Uncontrolled Type 2 Diabetes with COPD',
                    risk_level='high', asha_worker_name='Kavita Jadhav',
                    next_followup_date=date(2026, 9, 1), status='active',
                    notes='Insulin adjustment needed, spirometry follow-up'),
                HighRiskPatient(patient_id=patients[1].id, category='chronic',
                    condition_details='Hypertension - resistant to medication',
                    risk_level='medium', asha_worker_name='Sunita Pawar',
                    next_followup_date=date(2026, 9, 5), status='active',
                    notes='Check for secondary causes'),
            ]
            db.session.add_all(records)
            db.session.commit()
            print("Seeded 3 high-risk records.")


def seed_visits():
    if Visit.query.count() == 0:
        patients = Patient.query.all()
        facilities = Facility.query.all()
        if patients and facilities:
            visits_data = [
                Visit(patient_id=patients[0].id, facility_id=facilities[3].id,
                    doctor_name='Dr. Priya Kulkarni',
                    chief_complaint='High-risk pregnancy monitoring',
                    diagnosis='Gestational diabetes controlled, Anemia improving',
                    prescription='Insulin Glargine 10U,Iron Sucrose IV 200mg,Folic Acid 5mg,Calcium 500mg',
                    vitals_json=json.dumps({'HR': 78, 'BP': '126/82', 'SpO2': 98, 'Temp': 36.8}),
                    notes='Fetal growth on track'),
                Visit(patient_id=patients[0].id, facility_id=facilities[2].id,
                    doctor_name='Dr. Anil Patil',
                    chief_complaint='Follow-up for GDM, fatigue',
                    diagnosis='Gestational Diabetes, Iron deficiency anemia',
                    prescription='Metformin 500mg BD,Ferrous Fumarate 300mg,Folic Acid 5mg',
                    vitals_json=json.dumps({'HR': 84, 'BP': '132/86', 'SpO2': 97, 'Temp': 37.0}),
                    notes='HbA1c elevated. Referred to DH.'),
                Visit(patient_id=patients[1].id, facility_id=facilities[1].id,
                    doctor_name='Dr. Anil Patil',
                    chief_complaint='Headache and dizziness',
                    diagnosis='Hypertension Stage 2',
                    prescription='Amlodipine 10mg OD,Losartan 50mg OD',
                    vitals_json=json.dumps({'HR': 88, 'BP': '158/96', 'SpO2': 97, 'Temp': 36.6}),
                    notes='Referred for 24h BP monitoring'),
                Visit(patient_id=patients[3].id, facility_id=facilities[2].id,
                    doctor_name='Dr. Sneha Iyer',
                    chief_complaint='Breathlessness and high sugar',
                    diagnosis='Type 2 DM uncontrolled, COPD exacerbation',
                    prescription='Insulin Mixtard 30/70,Salbutamol inhaler,Metformin 1g BD',
                    vitals_json=json.dumps({'HR': 96, 'BP': '142/88', 'SpO2': 92, 'Temp': 37.2}),
                    notes='Needs pulmonology referral'),
            ]
            db.session.add_all(visits_data)
            db.session.commit()
            print("Seeded 4 visits.")


# ================= AI PROXY (keeps API key server-side) =================

OPENROUTER_KEY = os.getenv('OPENROUTER_API_KEY', '')

@app.route('/api/ai/chat', methods=['POST'])
def ai_chat_proxy():
    data = request.get_json()
    if not data or 'messages' not in data:
        return jsonify({'error': 'messages required'}), 400

    payload = {
        'model': data.get('model', 'openai/gpt-4o-mini'),
        'messages': data['messages'],
        'temperature': data.get('temperature', 0.7),
    }

    resp = req_lib.post(
        'https://openrouter.ai/api/v1/chat/completions',
        headers={
            'Authorization': f'Bearer {OPENROUTER_KEY}',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://tandurust.app',
            'X-Title': 'Tandurust'
        },
        json=payload,
        timeout=30
    )
    return jsonify(resp.json()), resp.status_code


# ================= MAIN =================
def init_db():
    with app.app_context():
        db.create_all()
        seed_facilities()
        seed_asha_workers()
        seed_patients()
        seed_doctors()
        seed_high_risk()
        seed_visits()

init_db()

if __name__ == "__main__":
    print(f"\nDatabase: {'NeonDB PostgreSQL' if 'neon' in DATABASE_URL else 'SQLite (local)'}")
    print("Starting Tandurust backend on http://127.0.0.1:5000")
    socketio.run(app, debug=True, use_reloader=False, host='0.0.0.0', port=5000)
