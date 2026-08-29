import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../data/chat_translate.dart';
import '../../../data/service_report.dart';
import '../../../domain/models/crm_models.dart';
import 'bay_live_camera.dart';

class ServiceReportPanel extends ConsumerStatefulWidget {
  const ServiceReportPanel({super.key, required this.order});

  final WorkOrder order;

  @override
  ConsumerState<ServiceReportPanel> createState() => _ServiceReportPanelState();
}

class _ServiceReportPanelState extends ConsumerState<ServiceReportPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<ServiceChatMessage> _messages(WorkOrder order) {
    return order.chat.isNotEmpty ? order.chat : seedServiceChat(order);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    final order = widget.order;
    final seed = seedServiceChat(order);
    _input.clear();
    setState(() => _sending = true);
    final writerLang = ref.read(localeProvider);
    ref.read(ordersProvider.notifier).addChat(
          order.id,
          ServiceChatMessage(
            id: '${order.id}_${DateTime.now().millisecondsSinceEpoch}',
            fromShop: false,
            text: ChatTranslate.localize(text, writerLang),
            at: DateTime.now(),
          ),
          seed: seed,
        );
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }
    final replyAt = DateTime.now();
    ref.read(ordersProvider.notifier).addChat(
          order.id,
          ServiceChatMessage(
            id: '${order.id}_r${replyAt.millisecondsSinceEpoch}',
            fromShop: true,
            text: shopChatReply(replyAt.second),
            at: replyAt,
          ),
        );
    setState(() => _sending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openItem(List<ServiceReportItem> items, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _ReportViewer(items: items, start: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(localeProvider);
    final palette = paletteOf(context);
    final order = ref.watch(ordersProvider.select((orders) {
      for (final item in orders) {
        if (item.id == widget.order.id) {
          return item;
        }
      }
      return widget.order;
    }));
    final items = incomingReport(order);
    final messages = _messages(order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.serviceReport,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 8),
        BayLiveCamera(
          assets: bayCameraAssets(order),
          seed: order.id,
          liveLabel: s.bayLive,
        ),
        const SizedBox(height: 8),
        Text(
          s.bayCamera,
          style: TextStyle(color: palette.muted, fontSize: 13),
        ),
        const SizedBox(height: 18),
        Text(
          s.reportGallery,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _GalleryTile(
                item: item,
                lang: lang,
                photoLabel: s.reportStill,
                videoLabel: s.reportClip,
                onTap: () => _openItem(items, index),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Text(
          s.chatWithShop,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.stroke),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: ListView.builder(
                  controller: _scroll,
                  itemCount: messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            '…',
                            style: TextStyle(color: palette.muted, fontSize: 18),
                          ),
                        ),
                      );
                    }
                    final message = messages[index];
                    return _ChatBubble(message: message, lang: lang);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: s.chatHint,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(CupertinoIcons.paperplane_fill, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.item,
    required this.lang,
    required this.photoLabel,
    required this.videoLabel,
    required this.onTap,
  });

  final ServiceReportItem item;
  final AppLang lang;
  final String photoLabel;
  final String videoLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      item.asset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
                    ),
                    if (item.video)
                      const Center(
                        child: Icon(
                          CupertinoIcons.play_circle_fill,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Text(
                        item.video ? videoLabel : photoLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.title.of(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.lang});

  final ServiceChatMessage message;
  final AppLang lang;

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(context);
    final mine = !message.fromShop;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
        decoration: BoxDecoration(
          color: mine ? palette.accent.withValues(alpha: 0.18) : palette.carbon.withValues(alpha: 0.55),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text.of(lang),
              style: TextStyle(color: palette.text, height: 1.35, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.at),
              style: TextStyle(color: palette.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportViewer extends StatefulWidget {
  const _ReportViewer({required this.items, required this.start});

  final List<ServiceReportItem> items;
  final int start;

  @override
  State<_ReportViewer> createState() => _ReportViewerState();
}

class _ReportViewerState extends State<_ReportViewer>
    with SingleTickerProviderStateMixin {
  late final PageController _pages;
  late final AnimationController _play;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.start;
    _pages = PageController(initialPage: widget.start);
    _play = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _syncPlay();
  }

  void _syncPlay() {
    if (widget.items[_index].video) {
      _play
        ..duration = const Duration(seconds: 12)
        ..repeat();
    } else {
      _play
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(item.title.uk, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: widget.items.length,
              onPageChanged: (index) {
                setState(() => _index = index);
                _syncPlay();
              },
              itemBuilder: (context, index) {
                final current = widget.items[index];
                return AnimatedBuilder(
                  animation: _play,
                  builder: (context, _) {
                    final zoom = current.video ? 1.0 + _play.value * 0.08 : 1.0;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Transform.scale(
                          scale: zoom,
                          child: Image.asset(
                            current.asset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.expand(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (item.video)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: AnimatedBuilder(
                animation: _play,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: _play.value,
                    minHeight: 3,
                    backgroundColor: const Color(0x44FFFFFF),
                    color: Colors.white,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
