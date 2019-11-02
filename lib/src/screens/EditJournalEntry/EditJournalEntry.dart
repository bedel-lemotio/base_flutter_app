import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grateful/src/blocs/editJournalEntry/bloc.dart';
import 'package:grateful/src/blocs/imageHandler/bloc.dart';
import 'package:grateful/src/blocs/pageView/page_view_bloc.dart';
import 'package:grateful/src/blocs/pageView/page_view_event.dart';
import 'package:grateful/src/models/JournalEntry.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grateful/src/models/Photograph.dart';
import 'package:grateful/src/services/localizations/localizations.dart';
import 'package:grateful/src/widgets/DateSelectorButton.dart';
import 'package:grateful/src/widgets/ImageUploader.dart';
import 'package:grateful/src/widgets/JournalEntryInput.dart';
import 'package:grateful/src/widgets/Shadower.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class EditJournalEntryArgs {
  JournalEntry journalEntry;

  EditJournalEntryArgs({this.journalEntry});
}

class EditJournalEntry extends StatefulWidget {
  bool get wantKeepAlive => true;

  final JournalEntry item;
  EditJournalEntry({this.item});
  @override
  State<StatefulWidget> createState() {
    return _EditJournalEntryState(journalEntry: this.item);
  }
}

class _EditJournalEntryState extends State<EditJournalEntry>
    with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;

  JournalEntry _journalEntry;
  bool isEdit;
  final EditItemBloc _editJournalEntryBloc = EditItemBloc();

  _EditJournalEntryState({JournalEntry journalEntry})
      : this._journalEntry = journalEntry ?? JournalEntry(),
        isEdit = journalEntry != null {
    _journalEntryController.value = TextEditingValue(text: '');
  }

  List<Photograph> _photographs = [];

  final TextEditingController _journalEntryController = TextEditingController();

  final ImageHandlerBloc _imageHandlerBloc = ImageHandlerBloc();

  initState() {
    super.initState();
    _journalEntryController.value =
        TextEditingValue(text: _journalEntry.body ?? '');
    _photographs = _journalEntry.photographs ?? [];
  }

  dispose() {
    _editJournalEntryBloc.close();
    super.dispose();
  }

  clearEditState() {
    setState(() {
      _journalEntry = JournalEntry();
      isEdit = false;
      _photographs = [];
      _journalEntryController.value =
          TextEditingValue(text: _journalEntry.body ?? '');
      _imageHandlerBloc.add(SetPhotographs([]));
    });
  }

  build(c) {
    super.build(c);
    final AppLocalizations localizations = AppLocalizations.of(c);
    return BlocBuilder(
        bloc: _editJournalEntryBloc,
        builder: (BuildContext context, EditJournalEntryState state) {
          return Scaffold(
              appBar: AppBar(
                elevation: 0,
                leading: Container(),
                actions: <Widget>[
                  if (isEdit)
                    FlatButton(
                      child: Icon(Icons.clear),
                      onPressed: clearEditState,
                    )
                ],
              ),
              drawer: Drawer(
                  child: Container(
                color: Theme.of(context).backgroundColor,
              )),
              body: Container(
                color: Theme.of(context).backgroundColor,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            localizations.gratefulPrompt,
                            style:
                                TextStyle(color: Colors.white, fontSize: 24.0),
                            textAlign: TextAlign.center,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: DateSelectorButton(
                              onPressed: handlePickDate,
                              selectedDate: _journalEntry.date,
                              locale: Localizations.localeOf(c),
                            ),
                          ),
                          IconButton(
                            iconSize: 36.0,
                            icon: Icon(Icons.arrow_forward),
                            color: Colors.white,
                            onPressed: () {
                              if (_journalEntry.body != null) {
                                _editJournalEntryBloc
                                    .add(SaveJournalEntry(_journalEntry));
                              }

                              BlocProvider.of<PageViewBloc>(context)
                                  .add(NextPage());
                            },
                          ),
                          JournalInput(
                            onChanged: (text) {
                              setState(() {
                                _journalEntry.body = text;
                              });
                            },
                            controller: _journalEntryController,
                          ),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 30.0),
                              child: BlocBuilder<ImageHandlerBloc,
                                      ImageHandlerState>(
                                  bloc: _imageHandlerBloc,
                                  builder: (context, imageHandlerState) {
                                    if (imageHandlerState
                                        is InitialImageHandlerState) {
                                      _imageHandlerBloc.add(SetPhotographs(
                                          _journalEntry.photographs ??
                                              <Photograph>[]));
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (imageHandlerState
                                        is PhotographsLoaded) {
                                      return Wrap(
                                          alignment: WrapAlignment.start,
                                          direction: Axis.horizontal,
                                          children: <Widget>[
                                            ...imageHandlerState.photographs
                                                .map<Widget>((i) {
                                              Widget child;
                                              if (i is NetworkPhoto) {
                                                child = CachedNetworkImage(
                                                  imageUrl: i.imageUrl,
                                                  imageBuilder: (c, p) {
                                                    return Shadower(
                                                        child: Image(
                                                      fit: BoxFit.cover,
                                                      height: 100,
                                                      width: 100,
                                                      image: p,
                                                    ));
                                                  },
                                                );
                                              } else if (i is FilePhoto) {
                                                child = Shadower(
                                                    child: ImageUploader(
                                                  file: i.file,
                                                  onComplete:
                                                      (String imageUrl) {
                                                    final newPhoto =
                                                        NetworkPhoto(
                                                            imageUrl: imageUrl);
                                                    _imageHandlerBloc.add(
                                                        ReplaceFilePhotoWithNetworkPhoto(
                                                            photograph:
                                                                newPhoto,
                                                            filePhotoGuid:
                                                                i.guid));

                                                    _journalEntry.photographs
                                                        .add(newPhoto);
                                                  },
                                                ));
                                              } else {
                                                child = Container();
                                              }
                                              return Padding(
                                                  padding: EdgeInsets.all(3.0),
                                                  child: child);
                                            }).toList(),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(3.0),
                                              child: SizedBox(
                                                height: 100,
                                                width: 100,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        style:
                                                            BorderStyle.solid,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                  child: InkWell(
                                                    onTap: () async {
                                                      File file = await ImagePicker
                                                          .pickImage(
                                                              source:
                                                                  ImageSource
                                                                      .gallery);
                                                      if (file == null) {
                                                        return;
                                                      }
                                                      final FilePhoto photo =
                                                          new FilePhoto(
                                                              file: file,
                                                              guid:
                                                                  Uuid().v4());
                                                      _imageHandlerBloc.add(
                                                          AddPhotograph(photo));
                                                    },
                                                    child: Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: <Widget>[
                                                          Icon(Icons.add,
                                                              color:
                                                                  Colors.white),
                                                          Text(
                                                            localizations
                                                                .addPhotos,
                                                            style: Theme.of(
                                                                    context)
                                                                .primaryTextTheme
                                                                .body1,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          ]);
                                    }
                                    return Container();
                                  }))
                        ]),
                  ),
                ),
              ));
        });
  }

  void handlePickDate(context) async {
    DateTime newDate = await showDatePicker(
      context: context,
      initialDate: _journalEntry.date ?? DateTime.now(),
      firstDate: DateTime.parse('1900-01-01'),
      lastDate: DateTime.now(),
    );
    if (newDate != null) {
      setState(() {
        _journalEntry.date = newDate;
      });
    }
  }
}