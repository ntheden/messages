import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg_icons/flutter_svg_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multiavatar/multiavatar.dart';
import 'package:dart_bech32/dart_bech32.dart';


import '../router/delegate.dart';
import '../db/db.dart';
import '../db/crud.dart';
import '../util/messages_localizations.dart';
import '../util/parse.dart';
import '../util/screen.dart';

class RelayEdit extends StatefulWidget {
  List<Relay> relays = [];
  late Contact currentUser;
  late Relay? relay;

  RelayEdit(Map<String, dynamic> options, {Key? key}) : super(key: key) {
    currentUser = options['user'];
    relay = options['relay'];
  }

  @override
  _RelayEditState createState() => _RelayEditState();
}

class RelayData {
  String? name = '';
  String? url = '';
  String? notes = '';
}

class _RelayEditState extends State<RelayEdit> with RestorationMixin {
  final RouterDelegate routerDelegate = Get.put(MyRouterDelegate());
  RelayData relayData = RelayData();
  late FocusNode _name, _url, _notes;
  TextEditingController nameController = TextEditingController();
  TextEditingController urlController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  String _title = "New Relay";

  @override
  void initState() {
    super.initState();
    _name = FocusNode();
    _url = FocusNode();
    _notes = FocusNode();
    if (widget.relay != null) {
      updateFields(widget.relay!);
    }
  }

  void updateFields(Relay relay) {
    _title = 'Edit Relay - ${relay!.name}';
    relayData.name = relay!.name;
    relayData.url = relay!.url;
    relayData.notes = '';//relay!.notes; 
    nameController.text = relay!.name;
    urlController.text = relayData.url!;
    notesController.text = relayData.notes!;
  }

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    _notes.dispose();
    nameController.dispose();
    urlController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  @override
  String get restorationId => 'relay_edit';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_autoValidateModeIndex, 'autovalidate_mode');
  }

  final RestorableInt _autoValidateModeIndex =
      RestorableInt(AutovalidateMode.disabled.index);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _handleSubmitted() {
    final form = _formKey.currentState!;
    if (!form.validate()) {
      _autoValidateModeIndex.value =
          AutovalidateMode.always.index; // Start validating on every change.
      showInSnackBar(
        MessagesLocalizations.of(context)!.demoTextFieldFormErrors,
      );
      return;
    }
    form.save();
    showInSnackBar(
      "Saved ${relayData.url}",
    );

    insertRelay(
      url: urlController.text,
      name: nameController.text.isEmpty ? Url(urlController.text).domain! : nameController.text,
    );
    Navigator.pop(context);
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

  String? _validateUrl(String? text) {
    if (Url(text ?? '').domain == null) {
      return "Could not parse domain from url $text";
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
                        _title,
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
              SizedBox(
                height: 250.0,
                width: 250.0,
                child: Image.asset('assets/server.jpg'),
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
                restorationId: 'url_field',
                controller: urlController,
                textInputAction: TextInputAction.next,
                focusNode: _url,
                decoration: InputDecoration(
                  filled: true,
                  icon: SvgIcon(icon: SvgIconData(
                    'assets/nostr_logo_prpl.svg',
                  )),
                  hintText: 'wss://',
                  labelText: "Relay URL*",
                ),
                keyboardType: TextInputType.text,
                onSaved: (value) {
                  relayData.url = value;
                  _name.requestFocus();
                },
                onChanged: (value) { },
                maxLength: 256,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                validator: _validateUrl,
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'name_field',
                controller: nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  filled: true,
                  icon: const Icon(Icons.computer),
                  hintText: "Optional name",
                  labelText: "Name",
                ),
                onSaved: (value) {
                  relayData.name = value;
                  _notes.requestFocus();
                },
                //validator: _validateName,
                onChanged: (value) {
                  setState(() => _title = "${widget.relay == null ? 'New' : 'Edit'} Relay - $value");
                },
              ),
              sizedBoxSpace,
              TextFormField(
                restorationId: 'notes_field',
                controller: notesController,
                focusNode: _notes,
                decoration: InputDecoration(
                  icon: const Icon(Icons.notes),
                  border: const OutlineInputBorder(),
                  hintText: "Enter notes here",
                  helperText: "Any notes you would like to add on the relay",
                  labelText: "Notes",
                ),
                maxLines: 3,
              ),
              sizedBoxSpace,
              Center(
                child: Container(
                  height: 50,
                  width: screenAwareWidth(0.5, context),
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: TextButton(
                    onPressed: _handleSubmitted,
                    child: Text(
                      'Save',
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
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
