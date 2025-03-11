import 'package:flutter/material.dart';

class InfiniteScrollList<T> extends StatefulWidget {
  final Future<List<T>> Function(int page) onLoadMore;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int initialItemCount;
  final String? emptyMessage;

  const InfiniteScrollList({
    super.key,
    required this.onLoadMore,
    required this.itemBuilder,
    this.initialItemCount = 20,
    this.emptyMessage,
  });

  @override
  State<InfiniteScrollList<T>> createState() => _InfiniteScrollListState<T>();
}

class _InfiniteScrollListState<T> extends State<InfiniteScrollList<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newItems = await widget.onLoadMore(_currentPage);
      if (newItems.isEmpty) {
        setState(() => _hasMore = false);
      } else {
        setState(() {
          _items.addAll(newItems);
          _currentPage++;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && !_isLoading) {
      return Center(
        child: Text(widget.emptyMessage ?? 'No items found'),
      );
    }

    return ListView.builder(
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          _loadMore();
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return widget.itemBuilder(context, _items[index]);
      },
    );
  }
}
