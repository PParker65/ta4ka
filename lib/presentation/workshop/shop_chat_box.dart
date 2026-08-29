import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/chat_translate.dart';
import '../../data/service_report.dart';
import '../../domain/models/crm_models.dart';
import 'shop_jobs.dart';

class ShopChatBox extends ConsumerStatefulWidget {
  const ShopChatBox({
    super.key,
    required this.order,
    this.compact = false,
    this.withMaster = false,
  });

  final WorkOrder order;
  final bool compact;
  final bool withMaster;

  @override
  ConsumerState<ShopChatBox> createState() => _ShopChatBoxState();
}

class _ShopChatBoxState extends ConsumerState<ShopChatBox> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) {
      return;
    }
    final order = widget.order;
    _input.clear();
    final base = order.chat.isNotEmpty
        ? order.chat
        : [...seedServiceChat(order), ...seedMasterChat(order)];
    final writerLang = ref.read(localeProvider);
    ref.read(ordersProvider.notifier).save(
          order.copyWith(
            chat: [
              ...base,
              ServiceChatMessage(
                id: '${order.id}_${widget.withMaster ? 'm' : 's'}${DateTime.now().millisecondsSinceEpoch}',
                fromShop: true,
                withMaster: widget.withMaster,
                text: ChatTranslate.localize(text, writerLang),
                at: DateTime.now(),
              ),
            ],
          ),
        );
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
    final messages =
        widget.withMaster ? masterThread(order) : shopThread(order);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        children: [
          SizedBox(
            height: widget.compact ? 160 : 220,
            child: ListView.builder(
              controller: _scroll,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final mine = message.fromShop;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
                    decoration: BoxDecoration(
                      color: mine
                          ? palette.accent.withValues(alpha: 0.18)
                          : palette.carbon.withValues(alpha: 0.55),
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
                          style: TextStyle(
                            color: palette.text,
                            height: 1.35,
                            fontSize: 14,
                          ),
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
                    hintText: widget.withMaster
                        ? s.shopMasterChatHint
                        : s.shopChatHint,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _send,
                icon: const Icon(CupertinoIcons.paperplane_fill, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
