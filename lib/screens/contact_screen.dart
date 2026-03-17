import 'package:flutter/material.dart';
import '../models/contact_model.dart';

class ContactScreen extends StatefulWidget {
  final List<EmergencyContact> contacts;
  final VoidCallback saveContacts;

  const ContactScreen({
    super.key,
    required this.contacts,
    required this.saveContacts,
  });

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {

TextEditingController controller = TextEditingController();

int maxContacts = 5;

void addContact() {

  // 🔹 Limit contacts
  if (widget.contacts.length >= maxContacts) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Maximum 5 contacts allowed"),
      ),
    );
    return;
  }

  String number = controller.text.trim();

  // 🔹 Remove spaces
  number = number.replaceAll(" ", "");

  // 🔹 Validate phone number (10 digits only)
  if (!RegExp(r'^[0-9]{10}$').hasMatch(number)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Enter valid 10-digit mobile number"),
      ),
    );
    return;
  }

  // 🔹 Prevent duplicate numbers
  bool alreadyExists =
      widget.contacts.any((contact) => contact.number == number);

  if (alreadyExists) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("This number already exists"),
      ),
    );
    return;
  }

  // 🔹 Add contact
  setState(() {
    widget.contacts.add(
      EmergencyContact(
        number: number,
        isPrimary: widget.contacts.isEmpty, // first contact = primary
      ),
    );
    controller.clear();
  });

  // 🔹 Save contacts locally
  widget.saveContacts();
}

void removeContact(int index) {
  setState(() {
    widget.contacts.removeAt(index);
  });

  widget.saveContacts();
}

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Emergency Contacts"),
      backgroundColor: Colors.blue,
    ),
    body: Column(
      children: [

        // 🔹 ADD CONTACT ROW
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: "Enter phone number",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: addContact,
              ),
            ],
          ),
        ),

        // 🔹 CONTACT LIST
        Expanded(
          child: ListView.builder(
            itemCount: widget.contacts.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(widget.contacts[index].number),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // PRIMARY CONTACT CHECKBOX
                      Checkbox(
                        value: widget.contacts[index].isPrimary,
                        onChanged: (value) async {
                          if (value == true) {

                            bool? confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Confirm Primary Contact"),
                                content: const Text(
                                  "Are you sure you want to promote this contact as Primary?\n\nOnly Primary contact will receive CALL.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Confirm"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              setState(() {
                                for (var contact in widget.contacts) {
                                  contact.isPrimary = false;
                                }

                                widget.contacts[index].isPrimary = true;
                              });

                              widget.saveContacts();
                            }
                          }
                        },
                      ),

                      // DELETE BUTTON
                      IconButton(
                        icon:
                            const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (widget.contacts[index].isPrimary) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Primary contact cannot be deleted. Promote another contact first.",
                                ),
                              ),
                            );
                          } else {
                            removeContact(index);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 🔹 CONTACT COUNTER
        Container(
         margin: const EdgeInsets.fromLTRB(10, 0, 10, 50),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.pink),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people, color: Colors.pink),
              const SizedBox(width: 8),
              Text(
                "Contacts: ${widget.contacts.length} / $maxContacts",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
        ),

      ],
    ),
  );
}}