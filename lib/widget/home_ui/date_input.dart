import 'package:bladi_go_client/widget/inputdecor.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class DateInputWidget extends StatefulWidget {
  final TextEditingController dateController;
  final IconData prefixIcon;
  final String? Function(String?)? validator;

  const DateInputWidget({
    super.key,
    required this.dateController,
    this.validator,
    this.prefixIcon = Icons.calendar_today_outlined,
  });

  @override
  State<DateInputWidget> createState() => _DateInputWidgetState();
}

class _DateInputWidgetState extends State<DateInputWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextFormField( // Changé de TextField à TextFormField
          controller: widget.dateController,
          decoration: InputDecorationBuilder.buildInputDecoration(
            labelText: 'Date',
            icon: widget.prefixIcon,
            hintText: 'Choisir une date', // Traduit en français
          ),
          readOnly: true,
          onTap: () async {
            DateTime? selectedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2101),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color.fromARGB(255, 46, 185, 255),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                   
                  ),
                  child: child!,
                );
              },
            );
            if (selectedDate != null) {
              String formattedDate = DateFormat('yyyy/MM/dd').format(selectedDate);
              widget.dateController.text = formattedDate;
            }
          },
          validator: widget.validator ?? (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner une date'; // Message corrigé
            }
            return null;
          },
        ),
      ],
    );
  }
}