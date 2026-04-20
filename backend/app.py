from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import numpy as np
import tensorflow as tf

app = Flask(__name__)
CORS(app)

# ================= DATABASE SETUP =================
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///tandurust.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# ================= LOAD TFLITE MODEL =================
interpreter = tf.lite.Interpreter(model_path="esi_model.tflite")
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("MODEL INPUT SHAPE:", input_details[0]["shape"])

# ================= USER MODEL =================
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(150), unique=True, nullable=False)
    password_hash = db.Column(db.String(200), nullable=False)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

# ================= BASIC ROUTE =================
@app.route("/")
def home():
    return "Tandurust backend is running ✅"

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
    else:
        return jsonify({'error': 'Invalid credentials'}), 401

# ================= SINGLE PATIENT PREDICTION =================
@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.json
        features = data.get("features")

        if not features:
            return jsonify({"error": "No features provided"}), 400

        input_data = np.array([features], dtype=np.float32)

        interpreter.set_tensor(input_details[0]["index"], input_data)
        interpreter.invoke()

        output = interpreter.get_tensor(output_details[0]["index"])[0]

        predicted_class = int(np.argmax(output))
        confidence = float(np.max(output))

        triage_map = {
            0: {"esi_level": 5, "label": "Non-Urgent 🟢"},
            1: {"esi_level": 4, "label": "Less Urgent 🟡"},
            2: {"esi_level": 3, "label": "Urgent 🟠"},
            3: {"esi_level": 2, "label": "Emergency 🔴"},
            4: {"esi_level": 1, "label": "Immediate 🚨"}
        }

        result = triage_map[predicted_class]

        return jsonify({
            "esi_level": result["esi_level"],
            "triage_label": result["label"],
            "confidence": confidence
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ================= MULTIPLE PATIENT TRIAGE =================
@app.route("/triage-multiple", methods=["POST"])
def triage_multiple():
    try:
        data = request.json
        patients = data.get("patients")

        if not patients:
            return jsonify({"error": "No patient data provided"}), 400

        triage_map = {
            0: {"esi_level": 5, "label": "Non-Urgent 🟢"},
            1: {"esi_level": 4, "label": "Less Urgent 🟡"},
            2: {"esi_level": 3, "label": "Urgent 🟠"},
            3: {"esi_level": 2, "label": "Emergency 🔴"},
            4: {"esi_level": 1, "label": "Immediate 🚨"}
        }

        results = []

        for patient in patients:
            name = patient["name"]
            features = patient["features"]

            input_data = np.array([features], dtype=np.float32)
            interpreter.set_tensor(input_details[0]["index"], input_data)
            interpreter.invoke()

            output = interpreter.get_tensor(output_details[0]["index"])[0]
            predicted_class = int(np.argmax(output))
            confidence = float(np.max(output))

            result = triage_map[predicted_class]

            results.append({
                "name": name,
                "esi_level": result["esi_level"],
                "triage_label": result["label"],
                "confidence": confidence
            })

        results.sort(key=lambda x: x["esi_level"])

        return jsonify({
            "most_critical_patient": results[0],
            "all_patients_sorted": results
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ================= MAIN =================
if __name__ == "__main__":
    with app.app_context():
        db.create_all()   # create User table

    app.run(debug=True, use_reloader=False)
