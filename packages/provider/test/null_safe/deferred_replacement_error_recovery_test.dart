import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  for (final lazy in [true, false]) {
    testWidgets(
        'retained callback notifies after failed replacement lazy=$lazy',
        (tester) async {
      final first = Object();
      final second = Object();
      var attempts = 0;
      var removals = 0;
      late void Function(int) emit;
      final consumer = Builder(
        builder: (context) =>
            Text('${context.watch<int>()}', textDirection: TextDirection.ltr),
      );
      final previousErrorBuilder = ErrorWidget.builder;
      ErrorWidget.builder = (_) => consumer;
      addTearDown(() => ErrorWidget.builder = previousErrorBuilder);
      Widget provider(Object controller) =>
          DeferredInheritedProvider<Object, int>.value(
            value: controller,
            lazy: lazy,
            startListening: (_, setState, current, previous) {
              emit = setState;
              if (identical(current, second) && attempts++ == 0) {
                throw StateError('replacement failed');
              }
              setState(previous ?? 0);
              return () => removals++;
            },
            child: consumer,
          );

      await tester.pumpWidget(provider(first));
      await tester.pumpWidget(provider(second));
      expect(tester.takeException(), isA<StateError>());
      ErrorWidget.builder = previousErrorBuilder;
      expect(find.text('0'), findsOneWidget);
      expect(removals, 1);
      emit(2);
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(attempts, 2);
      await tester.pumpWidget(const SizedBox());
      expect(removals, 2);
    });
  }
}
