
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wanandroid_pro/pages/drawer/note/note_card.dart';
import 'package:wanandroid_pro/pages/drawer/todo/task_card.dart';
import 'package:wanandroid_pro/providers/note_provider.dart';

import '../../card_swiper/controller/card_swiper_controller.dart';
import '../../card_swiper/enums.dart';
import '../../card_swiper/properties/allowed_swipe_direction.dart';
import '../../card_swiper/widget/card_swiper.dart';
import '../../model/login/User.dart';
import '../../providers/task_provider.dart';

const cardColor = Color(0xFFFFF1BE);

@Deprecated("已废弃，不再使用")
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<WelcomePage>
    with AutomaticKeepAliveClientMixin<WelcomePage> {
  final CardSwiperController controller = CardSwiperController();
  String _nameValue = "";
  late User user;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _nameValue = '';
  }

  @override
  void dispose() {
    controller.dispose(); // Ensure controller is disposed
    super.dispose();
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    return true; // Ensure non-null return
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    return true; // Ensure non-null return
  }

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoNotifierProvider);
    super.build(context);
    final todaysDate = DateTime.now();
    final todaysTodos = todoState.items;

    /// 逻辑已改，不会有 todo 卡片了这里
    final cards = todaysTodos
        .map((todo) => TodoCard(
              key: Key(todo.id.toString()),
              todo: todo,
              showDescription: false,
            ))
        .toList();

    final thisWeeksTodos = todoState.items;

    final notes = ref.watch(noteProvider);
    final noteCards = notes
        .map((note) => NoteCard(
              key: Key(note.id.toString()),
              note: note,
            ))
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(children: [
        // 顶部内容保持不变
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 60.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '早上好\n$_nameValue',
                    style: const TextStyle(
                        fontSize: 32.0, fontWeight: FontWeight.w600),
                  ),
                  const CircleAvatar(
                    radius: 25.0,
                    backgroundImage: AssetImage('assets/images/default.jpg'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.calendar,
                        color: Colors.black,
                        size: 28.0,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            DateFormat.MMMEd()
                                .format(DateTime.now())
                                .toString(),
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: (todaysTodos.isEmpty
                        ? Container()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                CupertinoIcons.alarm_fill,
                                color: Colors.black,
                                size: 14.0,
                              ),
                              const SizedBox(width: 5.0),
                              Text(
                                'You have ${todaysTodos.length} task${todaysTodos.length > 1 ? 's' : ''} today',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )),
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
        // 动态高度布局
        Flexible(
          child: Column(
            children: [
              if (cards.isNotEmpty)
                Flexible(
                  flex: 2,
                  child: CardSwiper(
                    maxAngle: 40,
                    allowedSwipeDirection:
                        const AllowedSwipeDirection.symmetric(
                            horizontal: true, vertical: false),
                    controller: controller,
                    cardsCount: cards.length,
                    onSwipe: _onSwipe,
                    onUndo: _onUndo,
                    numberOfCardsDisplayed: cards.length > 3 ? 3 : cards.length,
                    backCardOffset: const Offset(0, -20),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    cardBuilder: (context, index, _, __) => cards[index],
                  ),
                ),
              if (noteCards.isNotEmpty)
                Flexible(
                  flex: 3,
                  child: CardSwiper(
                    maxAngle: 30,
                    allowedSwipeDirection:
                        const AllowedSwipeDirection.symmetric(
                            horizontal: true, vertical: false),
                    controller: controller,
                    cardsCount: noteCards.length,
                    onSwipe: _onSwipe,
                    onUndo: _onUndo,
                    numberOfCardsDisplayed:
                        noteCards.length > 3 ? 3 : noteCards.length,
                    backCardOffset: const Offset(0, -20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 20),
                    cardBuilder: (context, index, _, __) => noteCards[index],
                  ),
                ),
              if (cards.isEmpty && noteCards.isEmpty)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          height: 140,
                          child: Image.asset('assets/images/empty.jpg')),
                      const Text(
                        'No tasks for today',
                        style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                          height: 140,
                          child: Image.asset('assets/images/empty.jpg')),
                      const Text(
                        'No notes for today',
                        style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
