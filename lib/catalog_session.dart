import 'package:flutter/widgets.dart';

import 'data/catalog_store.dart';
import 'data/shift_store.dart';
import 'services/catalog_repository.dart';

class CatalogSession extends StatefulWidget {
  const CatalogSession({
    super.key,
    required this.uid,
    required this.repository,
    required this.child,
  });
  final String uid;
  final CatalogRepository repository;
  final Widget child;
  @override
  State<CatalogSession> createState() => _CatalogSessionState();
}

class _CatalogSessionState extends State<CatalogSession> {
  late final CatalogStore _store;
  @override
  void initState() {
    super.initState();
    _store = CatalogStore(uid: widget.uid, repository: widget.repository);
    ShiftStore.instance.bindCatalog(_store);
  }

  @override
  void dispose() {
    ShiftStore.instance.unbindCatalog(_store);
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CatalogScope(store: _store, child: widget.child);
}
