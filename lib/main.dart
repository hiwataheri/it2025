import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// 1. Ticket Class: Defines the structure of a ticket
class Ticket {
  String issue;
  String description;
  String status;
  String priority; // Added priority field
  DateTime createdAt;

  Ticket({
    required this.issue,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  // Get status color
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  // Get priority color
  Color getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Convert Ticket to Map for saving in SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'issue': issue,
      'description': description,
      'status': status,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convert Map to Ticket object
  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      issue: map['issue'],
      description: map['description'],
      status: map['status'],
      priority: map['priority'] ?? 'Low', // Default priority
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

// 2. TicketManager: Manages the tickets in memory and uses SharedPreferences
class TicketManager {
  static late SharedPreferences _prefs;
  static const _key = 'tickets';

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Load all tickets
  static List<Ticket> loadTickets() {
    final List<String>? ticketsJson = _prefs.getStringList(_key);
    if (ticketsJson == null) {
      return [];
    }
    return ticketsJson.map((e) => Ticket.fromMap(jsonDecode(e))).toList();
  }

  // Save a new ticket
  static Future<void> saveTicket(Ticket ticket) async {
    final tickets = loadTickets();
    tickets.add(ticket);
    await _prefs.setStringList(
        _key, tickets.map((e) => jsonEncode(e.toMap())).toList());
  }

  // Delete a ticket
  static Future<void> deleteTicket(int index) async {
    final tickets = loadTickets();
    tickets.removeAt(index);
    await _prefs.setStringList(
        _key, tickets.map((e) => jsonEncode(e.toMap())).toList());
  }

  // Update a ticket
  static Future<void> updateTicket(int index, Ticket ticket) async {
    final tickets = loadTickets();
    tickets[index] = ticket;
    await _prefs.setStringList(
        _key, tickets.map((e) => jsonEncode(e.toMap())).toList());
  }
}

// 3. TicketScreen: Displays the list of tickets and allows for creating a new ticket
class TicketScreen extends StatefulWidget {
  @override
  _TicketScreenState createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  List<Ticket> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    setState(() {
      _tickets = TicketManager.loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ticket System',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (_tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.support_agent,
              size: 100,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'No tickets yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Create your first ticket',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadTickets();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          return TicketCard(
            ticket: ticket,
            index: index,
            onDelete: () {
              _showDeleteDialog(index);
            },
            onTap: () {
              _editTicket(index);
            },
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TicketForm()),
        ).then((_) => _loadTickets());
      },
      icon: Icon(Icons.add_circle_outline, size: 28),
      label: Text(
        'New Ticket',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Ticket'),
        content: Text('Are you sure you want to delete this ticket?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              TicketManager.deleteTicket(index);
              _loadTickets();
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _editTicket(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketForm(
          ticket: _tickets[index],
          index: index,
        ),
      ),
    ).then((_) => _loadTickets());
  }
}

// 4. TicketCard: Displays a ticket in a beautiful card
class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const TicketCard({
    Key? key,
    required this.ticket,
    required this.index,
    required this.onDelete,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ticket.issue,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                        value: 'edit',
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                        value: 'delete',
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                      if (value == 'edit') onTap();
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                ticket.description,
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusChip(),
                  SizedBox(width: 8),
                  _buildPriorityChip(),
                  Spacer(),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Chip(
      label: Text(
        ticket.status,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: ticket.getStatusColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildPriorityChip() {
    return Chip(
      label: Text(
        ticket.priority,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: ticket.getPriorityColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

// 5. TicketForm: Form for creating and editing tickets
class TicketForm extends StatefulWidget {
  final Ticket? ticket;
  final int? index;

  TicketForm({this.ticket, this.index});

  @override
  _TicketFormState createState() => _TicketFormState();
}

class _TicketFormState extends State<TicketForm> {
  final _formKey = GlobalKey<FormState>();
  final _issueController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _status = 'Open';
  String _priority = 'Low';
  final List<String> _statusOptions = [
    'Open',
    'In Progress',
    'Resolved',
    'Closed'
  ];
  final List<String> _priorityOptions = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    if (widget.ticket != null) {
      _issueController.text = widget.ticket!.issue;
      _descriptionController.text = widget.ticket!.description;
      _status = widget.ticket!.status;
      _priority = widget.ticket!.priority;
    }
  }

  void _submitTicket() async {
    if (_formKey.currentState!.validate()) {
      final newTicket = Ticket(
        issue: _issueController.text,
        description: _descriptionController.text,
        status: _status,
        priority: _priority,
        createdAt: widget.ticket?.createdAt ?? DateTime.now(),
      );

      if (widget.index == null) {
        await TicketManager.saveTicket(newTicket);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await TicketManager.updateTicket(widget.index!, newTicket);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket updated successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket == null ? 'Create Ticket' : 'Edit Ticket'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.ticket == null ? 'Create New Ticket' : 'Edit Ticket',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _issueController,
                decoration: InputDecoration(
                  labelText: 'Issue',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.bug_report),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an issue';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon:
                      Icon(Icons.circle, color: _getStatusColor(_status)),
                ),
                items: _statusOptions
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: _getStatusColor(value),
                        ),
                        SizedBox(width: 10),
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _status = newValue!;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon:
                      Icon(Icons.flag, color: _getPriorityColor(_priority)),
                ),
                items: _priorityOptions
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: _getPriorityColor(value),
                        ),
                        SizedBox(width: 10),
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _priority = newValue!;
                  });
                },
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _submitTicket,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.ticket == null ? Icons.send : Icons.save),
                      SizedBox(width: 10),
                      Text(
                        widget.ticket == null
                            ? 'Submit Ticket'
                            : 'Update Ticket',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// 6. Entry point of the app: main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TicketManager.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticket System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
      home: TicketScreen(),
    );
  }
}
