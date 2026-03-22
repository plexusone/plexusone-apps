import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/session.dart';
import '../theme/terminal_theme.dart';

/// Terminal-style output view
class TerminalView extends StatefulWidget {
  final List<OutputLine> lines;
  final bool autoScroll;

  const TerminalView({
    super.key,
    required this.lines,
    this.autoScroll = true,
  });

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(TerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScroll && _isAtBottom && widget.lines.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    _isAtBottom = currentScroll >= maxScroll - 50;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TerminalTheme.background,
      child: widget.lines.isEmpty
          ? const Center(
              child: Text(
                'No output yet',
                style: TextStyle(
                  color: TerminalTheme.foregroundDim,
                  fontFamily: 'monospace',
                ),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: widget.lines.length,
              itemBuilder: (context, index) {
                return TerminalLine(line: widget.lines[index]);
              },
            ),
    );
  }
}

/// Single line of terminal output
class TerminalLine extends StatelessWidget {
  final OutputLine line;

  const TerminalLine({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _copyToClipboard(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text(
          line.text.isEmpty ? ' ' : line.text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.4,
            color: _colorForStyle(line.style),
          ),
        ),
      ),
    );
  }

  Color _colorForStyle(LineStyle style) {
    switch (style) {
      case LineStyle.error:
        return TerminalTheme.red;
      case LineStyle.success:
        return TerminalTheme.green;
      case LineStyle.info:
        return TerminalTheme.blue;
      case LineStyle.command:
        return TerminalTheme.yellow;
      default:
        return TerminalTheme.foreground;
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: line.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
