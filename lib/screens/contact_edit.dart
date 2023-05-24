import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg_icons/flutter_svg_icons.dart';


import '../router/delegate.dart';
import '../db/db.dart';
import '../util/messages_localizations.dart';
import '../util/screen.dart';

class ContactEdit extends StatefulWidget {
  final Contact? contact;

  const ContactEdit(this.contact, {Key? key}) : super(key: key);

  @override
  _ContactEditState createState() => _ContactEditState();
}

class PersonData {
  String? name = '';
  String? npub = '';
  String? phoneNumber = '';
  String? email = '';
}

class _ContactEditState extends State<ContactEdit> with RestorationMixin {
  final RouterDelegate routerDelegate = Get.put(MyRouterDelegate());
  PersonData person = PersonData();
  late FocusNode _name, _npub, _phoneNumber, _email, _lifeStory;

  @override
  void initState() {
    super.initState();
    _phoneNumber = FocusNode();
    _name = FocusNode();
    _npub = FocusNode();
    _email = FocusNode();
    _lifeStory = FocusNode();
  }

  @override
  void dispose() {
    _npub.dispose();
    _name.dispose();
    _phoneNumber.dispose();
    _email.dispose();
    _lifeStory.dispose();
    super.dispose();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  @override
  String get restorationId => 'contact_edit';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_autoValidateModeIndex, 'autovalidate_mode');
  }

  final RestorableInt _autoValidateModeIndex =
      RestorableInt(AutovalidateMode.disabled.index);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _UsNumberTextInputFormatter _phoneNumberFormatter =
      _UsNumberTextInputFormatter();

  void _handleSubmitted() {
    final form = _formKey.currentState!;
    if (!form.validate()) {
      _autoValidateModeIndex.value =
          AutovalidateMode.always.index; // Start validating on every change.
      showInSnackBar(
        MessagesLocalizations.of(context)!.demoTextFieldFormErrors,
      );
    } else {
      form.save();
      showInSnackBar(MessagesLocalizations.of(context)!
          .demoTextFieldNameHasPhoneNumber(person.name!, person.phoneNumber!));
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return MessagesLocalizations.of(context)!.demoTextFieldNameRequired;
    }
    final nameExp = RegExp(r'^[A-Za-z ]+$');
    if (!nameExp.hasMatch(value)) {
      return MessagesLocalizations.of(context)!
          .demoTextFieldOnlyAlphabeticalChars;
    }
    return null;
  }

  String? _validateNpub(String? text) {
    final regexp = RegExp(r'[a-zA-Z0-9]+$');
    if (text!.startsWith('npub') && text!.contains(regexp)) {
      return null;
    }
    return 'Enter the 63 character word starting with "npub"';
  }

  String? _validatePhoneNumber(String? value) {
    final phoneExp = RegExp(r'^\(\d\d\d\) \d\d\d\-\d\d\d\d$');
    if (!phoneExp.hasMatch(value!)) {
      return MessagesLocalizations.of(context)!.demoTextFieldEnterUSPhoneNumber;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back, color: Colors.white,),
                ),
                SizedBox(width: 12,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        getTitle(),
                        style: TextStyle(fontSize: 16 ,fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                /*
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    // Switch to new/edit mode
                    print('@@@@@ switch to new/edit mode');
                  },
                ),
                */
              ],
            ),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.center,
        child: Container(
          height: screenAwareHeight(0.8, context),
          width: min(550, screenAwareWidth(0.8, context)),
          child: ListView(
            children: [
              //SizedBox(height: 5.0,),
              InkWell(
                // Open image picker
                onTap: () {
                  print('@@@@@ open image picker');
                  FilePicker.platform.pickFiles().then((result) {
                    if (result != null) {
                      //File file = File(result.files.single.path);
                    } else {
                      // User canceled the picker
                    }
                  });
                },
                child: widget.contact == null ?
                  CircleAvatar(
                    radius: 90,
                    backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                  ) : widget.contact!.avatar,
              ),
              buildForm(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildForm(BuildContext context) {
    const sizedBoxSpace = SizedBox(height: 24);
    final localizations = MessagesLocalizations.of(context)!;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.values[_autoValidateModeIndex.value],
      child: Scrollbar(
        child: SingleChildScrollView(
          restorationId: 'text_field_demo_scroll_view',
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              sizedBoxSpace,
              TextFormField(
                restorationId: 'npub_field',
                textInputAction: TextInputAction.next,
                focusNode: _npub,
                decoration: InputDecoration(
                  filled: true,
                  icon: SvgIcon(icon: SvgIconData(
                    'assets/nostr_logo_prpl.svg',
                  )),
                  hintText: "Enter npub",
                  labelText: "Nostr Public Key (npub)*",
                ),
                keyboardType: TextInputType.text,
                onSaved: (value) {
                  person.npub = value;
                  _name.requestFocus();
                },
                maxLength: 63,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                validator: _validateNpub,
                // TextInputFormatters are applied in sequence.
                /*
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  // Fit the validating format.
                  _phoneNumberFormatter,
                ],
                */
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'name_field',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  filled: true,
                  icon: const Icon(Icons.person),
                  hintText: "Will be retrieved from relay if not entered",
                  labelText: "Name",
                ),
                onSaved: (value) {
                  person.name = value;
                  _email.requestFocus();
                },
                //validator: _validateName,
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'email_field',
                textInputAction: TextInputAction.next,
                focusNode: _email,
                decoration: InputDecoration(
                  filled: true,
                  icon: const Icon(Icons.email),
                  hintText: "Contact's email address (optional)",
                  labelText: "Email",
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) {
                  person.email = value;
                  _phoneNumber.requestFocus();
                  _lifeStory.requestFocus();
                },
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'phone_number_field',
                textInputAction: TextInputAction.next,
                focusNode: _phoneNumber,
                decoration: InputDecoration(
                  filled: true,
                  icon: const Icon(Icons.phone),
                  hintText: "Enter a phone number for purple-pilling this contact",
                  labelText: "Phone number",
                ),
                keyboardType: TextInputType.phone,
                onSaved: (value) {
                  person.phoneNumber = value;
                  _lifeStory.requestFocus();
                },
                maxLength: 14,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                //validator: _validatePhoneNumber,
                // TextInputFormatters are applied in sequence.
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  // Fit the validating format.
                  _phoneNumberFormatter,
                ],
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'life_story_field',
                focusNode: _lifeStory,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Enter notes here",
                  helperText: "Any notes you would like to add on the contact",
                  labelText: "Notes",
                ),
                maxLines: 3,
              ),
              sizedBoxSpace,
              Center(
                child: ElevatedButton(
                  onPressed: _handleSubmitted,
                  child: Text("Save"),
                ),
              ),
              sizedBoxSpace,
              Text(
                localizations.demoTextFieldRequiredField,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              sizedBoxSpace,
            ],
          ),
        ),
      ),
    );
  }

  String getTitle() {
    if (widget.contact == null) {
      return 'New Contact';
    }
    // TODO: first/last name, else username
    return 'Edit Contact: ${widget.contact!.name}';
  } 
}

/// Format incoming numeric text to fit the format of (###) ###-#### ##
class _UsNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newTextLength = newValue.text.length;
    final newText = StringBuffer();
    var selectionIndex = newValue.selection.end;
    var usedSubstringIndex = 0;
    if (newTextLength >= 1) {
      newText.write('(');
      if (newValue.selection.end >= 1) selectionIndex++;
    }
    if (newTextLength >= 4) {
      newText.write('${newValue.text.substring(0, usedSubstringIndex = 3)}) ');
      if (newValue.selection.end >= 3) selectionIndex += 2;
    }
    if (newTextLength >= 7) {
      newText.write('${newValue.text.substring(3, usedSubstringIndex = 6)}-');
      if (newValue.selection.end >= 6) selectionIndex++;
    }
    if (newTextLength >= 11) {
      newText.write('${newValue.text.substring(6, usedSubstringIndex = 10)} ');
      if (newValue.selection.end >= 10) selectionIndex++;
    }
    // Dump the rest.
    if (newTextLength >= usedSubstringIndex) {
      newText.write(newValue.text.substring(usedSubstringIndex));
    }
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
