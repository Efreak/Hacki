import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/widgets/link_preview/web_analyzer.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.showExitButton = false,
  });

  final bool showExitButton;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoriesBloc, StoriesState>(
      buildWhen: (StoriesState previous, StoriesState current) =>
          previous.offlineReading != current.offlineReading,
      builder: (BuildContext context, StoriesState state) {
        if (state.offlineReading) {
          return MaterialBanner(
            content: Text(
              'You are currently in offline mode. '
              '${showExitButton ? 'Exit to fetch latest stories.' : ''}',
              textAlign: showExitButton ? TextAlign.left : TextAlign.center,
            ),
            backgroundColor: Colors.orangeAccent.withOpacity(0.3),
            actions: <Widget>[
              if (showExitButton)
                TextButton(
                  onPressed: () {
                    showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Exit offline mode?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Yes',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ).then((bool? value) {
                      if (value ?? false) {
                        context.read<StoriesBloc>().add(StoriesExitOffline());
                        context.read<AuthBloc>().add(AuthInitialize());
                        context.read<PinCubit>().init();
                        WebAnalyzer.cacheMap.clear();
                      }
                    });
                  },
                  child: const Text('Exit'),
                )
              else
                Container(),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
