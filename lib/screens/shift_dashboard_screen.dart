import 'package:material_ui/material_ui.dart';

import '../data/catalog_store.dart';
import '../data/session_store.dart';
import '../services/catalog_repository.dart';
import '../services/community_models.dart';
import '../services/shift_dashboard_repository.dart';

class ShiftDashboardScreen extends StatelessWidget {
  const ShiftDashboardScreen({super.key, required this.shiftId});

  final String shiftId;

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.maybeOf(context);
    return ListenableBuilder(
      listenable: SessionStore.instance,
      builder: (context, _) {
        final record = catalog?.shifts
            .where((entry) => entry.shift.id == shiftId)
            .firstOrNull;
        final leads =
            record != null &&
            catalog != null &&
            record.creatorUid == catalog.uid &&
            catalog.coordinatorBanks.contains(record.bankId);
        final canOpen =
            catalog != null &&
            record != null &&
            !SessionStore.instance.isKidAccount &&
            (leads || catalog.signups.contains(shiftId));
        return Scaffold(
          appBar: AppBar(title: const Text('Shift dashboard')),
          body:
              catalog != null && (catalog.shiftsLoading || catalog.shiftsFailed)
              ? Center(child: CatalogStatus(store: catalog, shifts: true))
              : canOpen
              ? _ShiftBoard(
                  key: ValueKey((catalog.uid, shiftId, leads)),
                  catalog: catalog,
                  record: record,
                  coordinator: leads,
                )
              : const Center(
                  child: Text(
                    'This dashboard is for the shift coordinator and booked adults.',
                  ),
                ),
        );
      },
    );
  }
}

class _ShiftBoard extends StatefulWidget {
  const _ShiftBoard({
    super.key,
    required this.catalog,
    required this.record,
    required this.coordinator,
  });

  final CatalogStore catalog;
  final StoredShift record;
  final bool coordinator;

  @override
  State<_ShiftBoard> createState() => _ShiftBoardState();
}

class _ShiftBoardState extends State<_ShiftBoard> {
  late final ShiftDashboardRepository _repository;
  late Stream<List<ShiftTask>> _tasks;
  late Stream<List<ShiftBoardMessage>> _messages;
  Stream<ShiftGroup>? _roster;
  final _message = TextEditingController();
  final _taskWrites = <String>{};
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _repository = ShiftDashboardRepository(
      widget.record.shift.id!,
      widget.catalog.uid,
    );
    _subscribe();
  }

  void _subscribe() {
    _tasks = _repository.watchTasks(coordinator: widget.coordinator);
    _messages = _repository.watchMessages();
    if (widget.coordinator) {
      _roster = widget.catalog.repository.watchGroup(widget.record.shift.id!);
    }
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(catalogError(error))));
    }
  }

  Future<void> _newTask() async {
    final form = GlobalKey<FormState>();
    var title = '';
    var station = widget.record.shift.station;
    final create = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add station task'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Task'),
                maxLength: 120,
                onChanged: (value) => title = value,
                validator: (value) =>
                    value!.trim().isEmpty ? 'Enter a task.' : null,
              ),
              TextFormField(
                initialValue: station,
                decoration: const InputDecoration(labelText: 'Station'),
                maxLength: 80,
                onChanged: (value) => station = value,
                validator: (value) =>
                    value!.trim().isEmpty || value.trim().length > 80
                    ? 'Enter a station of up to 80 characters.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Add task'),
          ),
        ],
      ),
    );
    if (create != true || !mounted) return;
    try {
      await _repository.createTask(title, station);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _update(
    ShiftTask task, {
    String? assignee,
    ShiftTaskStatus? status,
  }) async {
    if (!_taskWrites.add(task.id)) return;
    setState(() {});
    try {
      await _repository.updateTask(task, assigneeUid: assignee, status: status);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _taskWrites.remove(task.id));
    }
  }

  Future<void> _chooseVolunteer(
    ShiftTask task,
    List<MapEntry<String, String>> members,
  ) async {
    final uid = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign volunteer'),
        children: [
          if (task.assigneeUid.isNotEmpty)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Unassign'),
            ),
          for (final member in members)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, member.key),
              child: Text(member.value),
            ),
        ],
      ),
    );
    if (uid != null && mounted) await _update(task, assignee: uid);
  }

  Future<void> _post() async {
    final body = _message.text.trim();
    if (_posting || body.isEmpty || body.length > 1000) return;
    setState(() => _posting = true);
    try {
      await _repository.postMessage(body);
      if (mounted) _message.clear();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Widget _loadError(String label) => Row(
    children: [
      Expanded(child: Text('Could not load $label.')),
      TextButton(
        onPressed: () => setState(_subscribe),
        child: const Text('Retry'),
      ),
    ],
  );

  Widget _taskCard(ShiftTask task, List<MapEntry<String, String>> members) {
    if (!widget.coordinator) {
      return Card(
        child: ListTile(
          title: Text(task.title),
          trailing: Text(task.status.label),
        ),
      );
    }
    final busy = _taskWrites.contains(task.id);
    final assignee = members
        .where((member) => member.key == task.assigneeUid)
        .firstOrNull;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          !busy && members.any((member) => member.key == details.data),
      onAcceptWithDetails: (details) => _update(task, assignee: details.data),
      builder: (context, candidates, _) => Card(
        color: candidates.isEmpty
            ? null
            : Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                assignee?.value ??
                    (task.assigneeUid.isEmpty
                        ? 'Unassigned'
                        : 'Assigned volunteer is no longer booked'),
              ),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed:
                        busy || (members.isEmpty && task.assigneeUid.isEmpty)
                        ? null
                        : () => _chooseVolunteer(task, members),
                    child: const Text('Assign volunteer'),
                  ),
                  DropdownButton<ShiftTaskStatus>(
                    value: task.status,
                    icon: const Icon(Icons.expand_more),
                    onChanged: busy
                        ? null
                        : (status) {
                            if (status != null) _update(task, status: status);
                          },
                    items: [
                      for (final status in ShiftTaskStatus.values)
                        DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskSection(List<MapEntry<String, String>> members) =>
      StreamBuilder<List<ShiftTask>>(
        stream: _tasks,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _loadError('tasks');
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final stations = <String, List<ShiftTask>>{};
          for (final task in snapshot.data!) {
            (stations[task.station] ??= []).add(task);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stations.isEmpty)
                Text(
                  widget.coordinator
                      ? 'No station tasks yet.'
                      : 'You have no assignments yet.',
                ),
              for (final station in stations.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    station.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final task in station.value) _taskCard(task, members),
              ],
            ],
          );
        },
      );

  Widget _coordination() {
    if (!widget.coordinator) return _taskSection(const []);
    return StreamBuilder<ShiftGroup>(
      stream: _roster,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _loadError('the adult roster');
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final members = snapshot.data!.members.entries.toList()
          ..sort(
            (a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()),
          );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Booked adults',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (members.isEmpty)
              const Text('No adults are booked yet.')
            else
              Wrap(
                spacing: 8,
                children: [
                  for (final member in members)
                    Draggable<String>(
                      data: member.key,
                      feedback: Material(
                        type: MaterialType.transparency,
                        child: Chip(label: Text(member.value)),
                      ),
                      child: Chip(
                        avatar: const Icon(Icons.drag_indicator),
                        label: Text(member.value),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _newTask,
                icon: const Icon(Icons.add),
                label: const Text('Add task'),
              ),
            ),
            _taskSection(members),
          ],
        );
      },
    );
  }

  Widget _thread() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Shift messages', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      TextField(
        controller: _message,
        enabled: !_posting,
        maxLength: 1000,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Message the shift group'),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: _posting ? null : _post,
          child: Text(_posting ? 'Sending…' : 'Send message'),
        ),
      ),
      StreamBuilder<List<ShiftBoardMessage>>(
        stream: _messages,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _loadError('messages');
          if (!snapshot.hasData) return const LinearProgressIndicator();
          if (snapshot.data!.isEmpty) return const Text('No messages yet.');
          final labels = MaterialLocalizations.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final message in snapshot.data!)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.authorName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(message.body),
                        if (message.sentAt case final sentAt?)
                          Text(
                            '${labels.formatShortDate(sentAt)} · ${labels.formatTimeOfDay(TimeOfDay.fromDateTime(sentAt))}',
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.record.shift.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text('${widget.record.shift.date} · ${widget.record.shift.time}'),
          const SizedBox(height: 20),
          if (!widget.coordinator)
            Text(
              'Your assignments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          _coordination(),
          const Divider(height: 40),
          _thread(),
        ],
      ),
    ),
  );
}
