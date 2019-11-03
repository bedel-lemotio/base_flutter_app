import 'package:flutter/material.dart';
import 'package:grateful/src/blocs/itemFeed/bloc.dart';
import 'package:grateful/src/blocs/pageView/bloc.dart';
import 'package:grateful/src/models/JournalEntry.dart';
import 'package:grateful/src/repositories/JournalEntries/JournalEntryRepository.dart';
import 'package:grateful/src/screens/JournalEntryDetails/JournalEntryDetails.dart';
import 'package:grateful/src/services/localizations/localizations.dart';
import 'package:grateful/src/services/navigator.dart';
import 'package:grateful/src/services/routes.dart';
import 'package:grateful/src/widgets/AppDrawer/drawer.dart';
import 'package:grateful/src/widgets/JournalFeedListItem.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grateful/src/widgets/YearSeparator.dart';

class JournalEntryFeed extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _JournalEntryFeedState();
  }
}

class _JournalEntryFeedState extends State<JournalEntryFeed> {
  // final items = List.generate(20, (_) => Item.random());
  JournalEntryBloc _journalFeedBloc;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void initState() {
    _journalFeedBloc =
        JournalEntryBloc(journalEntryRepository: JournalEntryRepository());
    super.initState();
  }

  build(context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
        key: _scaffoldKey,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            BlocProvider.of<PageViewBloc>(context).add(SetPage(0));
          },
          child: Icon(Icons.edit),
        ),
        drawer: AppDrawer(),
        body: NestedScrollView(
          headerSliverBuilder: (context, isScrolled) {
            return [
              SliverAppBar(
                elevation: 0.0,
                title: Text(localizations.previousEntries),
                leading: FlatButton(
                  child: Icon(Icons.menu,
                      color: theme.appBarTheme.iconTheme.color),
                  onPressed: () {
                    _scaffoldKey.currentState.openDrawer();
                  },
                ),
              ),
            ];
          },
          body: BlocBuilder<JournalEntryBloc, JournalFeedState>(
            bloc: _journalFeedBloc,
            builder: (context, state) {
              if (state is JournalFeedUnloaded) {
                _journalFeedBloc.add(FetchFeed());
                return Container(
                  color: theme.backgroundColor,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (state is JournalFeedFetched) {
                final sortedEntries = List.from(state.journalEntries
                  ..sort((a, b) {
                    return a.date.isBefore(b.date) ? 1 : -1;
                  }));
                final Map<int, List<JournalEntry>> sortedEntriesYearMap =
                    sortedEntries.fold({}, (previous, current) {
                  final year = (current as JournalEntry).date.year;
                  if (previous[year] == null) {
                    previous[year] = [];
                  }
                  previous[year].add(current);
                  return previous;
                });
                final compiledList =
                    sortedEntriesYearMap.keys.fold<List<Widget>>([], (p, c) {
                  return p
                    ..addAll([
                      YearSeparator(c.toString()),
                      ...sortedEntriesYearMap[c].map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: JournalEntryListItem(
                            journalEntry: entry,
                            onPressed: () {
                              rootNavigationService.navigateTo(
                                  FlutterAppRoutes.journalEntryDetails,
                                  arguments: JournalEntryDetailArguments(
                                      journalEntry: entry));
                            },
                          ),
                        );
                      })
                    ]);
                });
                return Container(
                  color: theme.backgroundColor,
                  child: SafeArea(
                      child: ListView.builder(
                    itemBuilder: (context, index) {
                      return compiledList[index];
                    },
                    itemCount: compiledList.length,
                  )),
                );
              }
              return Container();
            },
          ),
        ));
  }
}
