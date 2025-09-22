// search_bar.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSuggestionSelected;

  const SearchBarWidget({
    Key? key,
    required this.onSearch,
    required this.onSuggestionSelected,
  }) : super(key: key);

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
    });
  }

  void _onSearchChanged(String query) async {
    widget.onSearch(query);
    
    if (query.length > 2) {
      final suggestions = await _dbHelper.getSearchSuggestions(query);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = _focusNode.hasFocus && suggestions.isNotEmpty;
      });
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _onSuggestionSelected(String suggestion) {
    _controller.text = suggestion;
    widget.onSuggestionSelected(suggestion);
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, serial o ID...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearSearch,
                        )
                      : Icon(Icons.search, color: Colors.grey),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (value) {
                  widget.onSearch(value);
                  _focusNode.unfocus();
                },
              ),
            ],
          ),
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Sugerencias:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ..._suggestions.map((suggestion) => ListTile(
                      leading: Icon(Icons.search, size: 20),
                      title: Text(suggestion),
                      onTap: () => _onSuggestionSelected(suggestion),
                      dense: true,
                    )),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }
}