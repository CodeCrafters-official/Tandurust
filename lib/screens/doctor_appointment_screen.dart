import 'package:flutter/material.dart';

class DoctorAppointmentScreen extends StatefulWidget {
  const DoctorAppointmentScreen({super.key});

  @override
  State<DoctorAppointmentScreen> createState() =>
      _DoctorAppointmentScreenState();
}

class _DoctorAppointmentScreenState extends State<DoctorAppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ------- Filters -------
  DateTime _selectedDate = DateTime.now();
  String _selectedSpecialty = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  // ------- Mock Doctors -------
  final List<_Doctor> _doctors = [
    _Doctor(
      id: 'd1',
      name: 'Dr. Meera Nair',
      specialty: 'General Physician',
      hospital: 'City Care Clinic',
      rating: 4.7,
      distanceKm: 1.2,
      defaultSlots: const [
        '09:00 AM',
        '09:30 AM',
        '10:00 AM',
        '10:30 AM',
        '11:30 AM',
        '02:00 PM',
        '02:30 PM',
        '03:00 PM',
        '04:00 PM',
      ],
    ),
    _Doctor(
      id: 'd2',
      name: 'Dr. Karthik Rao',
      specialty: 'Cardiologist',
      hospital: 'Heart & Vascular Center',
      rating: 4.8,
      distanceKm: 3.5,
      defaultSlots: const ['10:00 AM', '11:00 AM', '02:00 PM', '03:30 PM'],
    ),
    _Doctor(
      id: 'd3',
      name: 'Dr. Ananya Gupta',
      specialty: 'Dermatologist',
      hospital: 'SkinCare Hospital',
      rating: 4.5,
      distanceKm: 2.1,
      defaultSlots: const ['09:30 AM', '10:30 AM', '12:00 PM', '03:00 PM'],
    ),
    _Doctor(
      id: 'd4',
      name: 'Dr. Rohan Sharma',
      specialty: 'Pediatrician',
      hospital: 'Sunrise Children’s Clinic',
      rating: 4.6,
      distanceKm: 4.0,
      defaultSlots: const ['09:00 AM', '11:30 AM', '02:00 PM', '04:00 PM'],
    ),
  ];

  // ------- Mock booked slots store: doctorId -> yyyy-mm-dd -> set(times) -------
  final Map<String, Map<String, Set<String>>> _booked = {
    // pre-book a couple of slots as examples
    'd1': {
      _ymd(DateTime.now()): {'10:00 AM'},
    },
    'd2': {
      _ymd(DateTime.now()): {'11:00 AM'},
    },
  };

  // ------- My bookings (for the second tab) -------
  final List<_Booking> _myBookings = [];

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Doctor> _filteredDoctors() {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _doctors.where((d) {
      final matchesSpec =
          _selectedSpecialty == 'All' || d.specialty == _selectedSpecialty;
      final matchesQuery = q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.hospital.toLowerCase().contains(q) ||
          d.specialty.toLowerCase().contains(q);
      return matchesSpec && matchesQuery;
    }).toList();
  }

  List<String> _availableSlots(_Doctor doc, DateTime date) {
    final key = _ymd(date);
    final bookedForDay = _booked[doc.id]?[key] ?? <String>{};
    return doc.defaultSlots.where((s) => !bookedForDay.contains(s)).toList();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: _selectedDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _bookSlot(_Doctor doc, String time) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Text(
            'Book ${doc.name}\n${doc.specialty} at ${doc.hospital}\nOn ${_prettyDate(_selectedDate)} at $time ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final dayKey = _ymd(_selectedDate);
    _booked.putIfAbsent(doc.id, () => {});
    _booked[doc.id]!.putIfAbsent(dayKey, () => <String>{});
    _booked[doc.id]![dayKey]!.add(time);

    _myBookings.add(_Booking(
      doctorId: doc.id,
      doctorName: doc.name,
      specialty: doc.specialty,
      hospital: doc.hospital,
      date: _selectedDate,
      time: time,
    ));

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booked ${doc.name} at $time')),
    );
  }

  void _cancelBooking(_Booking b) {
    final dayKey = _ymd(b.date);
    _booked[b.doctorId]?[dayKey]?.remove(b.time);
    _myBookings.remove(b);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment canceled')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDoctors();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Doctor'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Find Doctors'),
            Tab(icon: Icon(Icons.calendar_month), text: 'My Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ----------- TAB 1: Find Doctors -----------
          Column(
            children: [
              _filtersBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search doctor / hospital / specialty',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                  child: Text('No doctors match your filters.'),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) =>
                      _doctorCard(filtered[i], _selectedDate),
                ),
              ),
            ],
          ),

          // ----------- TAB 2: My Bookings -----------
          _myBookings.isEmpty
              ? const Center(
            child: Text('No appointments yet.\nBook from Find Doctors.'),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _myBookings.length,
            itemBuilder: (_, i) => _bookingTile(_myBookings[i]),
          ),
        ],
      ),
    );
  }

  Widget _filtersBar() {
    final specs = ['All', 'General Physician', 'Cardiologist', 'Dermatologist', 'Pediatrician'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      _prettyDate(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSpecialty,
              items: specs
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSpecialty = v ?? 'All'),
              decoration: InputDecoration(
                labelText: 'Specialty',
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorCard(_Doctor d, DateTime date) {
    final slots = _availableSlots(d, date);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.teal.shade100,
                child: const Icon(Icons.person, color: Colors.teal),
              ),
              title: Text(
                d.name,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${d.specialty} • ${d.hospital}'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text('${d.rating}  •  ${d.distanceKm.toStringAsFixed(1)} km away'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text('Available slots',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            slots.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No slots for selected date. Try another date.'),
            )
                : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots
                  .map((t) => ActionChip(
                label: Text(t),
                avatar: const Icon(Icons.schedule, size: 18),
                onPressed: () => _bookSlot(d, t),
              ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _bookingTile(_Booking b) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.local_hospital, color: Colors.white),
        ),
        title: Text(
          b.doctorName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
            '${b.specialty} • ${b.hospital}\n${_prettyDate(b.date)} at ${b.time}'),
        isThreeLine: true,
        trailing: TextButton(
          onPressed: () => _cancelBooking(b),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  static String _prettyDate(DateTime d) {
    // e.g., Tue, Sep 3
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final wd = weekdays[d.weekday - 1];
    final m = months[d.month - 1];
    return '$wd, $m ${d.day}';
  }
}

// --------- Simple data classes (in-file) ---------
class _Doctor {
  final String id;
  final String name;
  final String specialty;
  final String hospital;
  final double rating;
  final double distanceKm;
  final List<String> defaultSlots;

  _Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.rating,
    required this.distanceKm,
    required this.defaultSlots,
  });
}

class _Booking {
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String hospital;
  final DateTime date;
  final String time;

  _Booking({
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    required this.date,
    required this.time,
  });
}
