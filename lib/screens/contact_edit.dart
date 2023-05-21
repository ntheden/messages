import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';


import '../router/delegate.dart';
import '../util/messages_localizations.dart';

class ContactEdit extends StatefulWidget {
  final String title;
  final String npub;

  const ContactEdit(this.npub, {Key? key, this.title='<Name of Contact>'}) : super(key: key);

  @override
  _ContactEditState createState() => _ContactEditState();
}

class _ContactEditState extends State<ContactEdit> {
  final RouterDelegate routerDelegate = Get.put(MyRouterDelegate());

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
                      Text('New Contact',
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
      body: Column(
        children: [
          SizedBox(height: 10.0,),
          InkWell(
            // Open image picker
            onTap: () => print('@@@@@ open image picker'),
            child: CircleAvatar(
              radius: 70,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
          ),
          TextFormFieldDemo(),
        ],
      ),
    );
  }
}


class TextFormFieldDemo extends StatefulWidget {
  TextFormFieldDemo({super.key});

  @override
  TextFormFieldDemoState createState() => TextFormFieldDemoState();
}

class PersonData {
  String? name = '';
  String? phoneNumber = '';
  String? email = '';
}

class TextFormFieldDemoState extends State<TextFormFieldDemo>
    with RestorationMixin {
  PersonData person = PersonData();

  late FocusNode _phoneNumber, _email, _lifeStory;

  @override
  void initState() {
    super.initState();
    _phoneNumber = FocusNode();
    _email = FocusNode();
    _lifeStory = FocusNode();
  }

  @override
  void dispose() {
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
  String get restorationId => 'text_field_demo';

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

  String? _validatePhoneNumber(String? value) {
    final phoneExp = RegExp(r'^\(\d\d\d\) \d\d\d\-\d\d\d\d$');
    if (!phoneExp.hasMatch(value!)) {
      return MessagesLocalizations.of(context)!.demoTextFieldEnterUSPhoneNumber;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                restorationId: 'name_field',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  filled: true,
                  icon: const Icon(Icons.person),
                  hintText: localizations.demoTextFieldWhatDoPeopleCallYou,
                  labelText: localizations.demoTextFieldNameField,
                ),
                onSaved: (value) {
                  person.name = value;
                  _phoneNumber.requestFocus();
                },
                validator: _validateName,
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'phone_number_field',
                textInputAction: TextInputAction.next,
                focusNode: _phoneNumber,
                decoration: InputDecoration(
                  filled: true,
                  icon: const Icon(Icons.phone),
                  hintText: localizations.demoTextFieldWhereCanWeReachYou,
                  labelText: localizations.demoTextFieldPhoneNumber,
                  prefixText: '+1 ',
                ),
                keyboardType: TextInputType.phone,
                onSaved: (value) {
                  person.phoneNumber = value;
                  _email.requestFocus();
                },
                maxLength: 14,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                validator: _validatePhoneNumber,
                // TextInputFormatters are applied in sequence.
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  // Fit the validating format.
                  _phoneNumberFormatter,
                ],
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'email_field',
                textInputAction: TextInputAction.next,
                focusNode: _email,
                decoration: InputDecoration(
                  filled: true,
                  icon: const Icon(Icons.email),
                  hintText: localizations.demoTextFieldYourEmailAddress,
                  labelText: localizations.demoTextFieldEmail,
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) {
                  person.email = value;
                  _lifeStory.requestFocus();
                },
              ),
              sizedBoxSpace,
              // Disabled text field
              TextFormField(
                enabled: false,
                restorationId: 'disabled_email_field',
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  filled: true,
                  icon: const Icon(Icons.email),
                  hintText: localizations.demoTextFieldYourEmailAddress,
                  labelText: localizations.demoTextFieldEmail,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'life_story_field',
                focusNode: _lifeStory,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: localizations.demoTextFieldTellUsAboutYourself,
                  helperText: localizations.demoTextFieldKeepItShort,
                  labelText: localizations.demoTextFieldLifeStory,
                ),
                maxLines: 3,
              ),
              sizedBoxSpace,
              Center(
                child: ElevatedButton(
                  onPressed: _handleSubmitted,
                  child: Text(localizations.demoTextFieldSubmit),
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


