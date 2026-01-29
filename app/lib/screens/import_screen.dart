import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/books_provider.dart';
import '../providers/shelves_provider.dart';
import '../services/book_service.dart';
import '../services/csv_import_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

enum ImportState { initial, preview, importing, complete }

class _ImportScreenState extends State<ImportScreen> {
  ImportState _state = ImportState.initial;
  ImportPreview? _preview;
  ImportProgress? _progress;
  CsvImportService? _importService;
  StreamSubscription<ImportProgress>? _progressSubscription;
  String? _error;

  // Import options
  bool _importRatings = true;
  bool _importDates = true;

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _importService?.dispose();
    super.dispose();
  }

  Future<void> _pickCsvFile() async {
    setState(() {
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final file = result.files.first;
      if (file.path == null) {
        setState(() {
          _error = 'Could not access the selected file';
        });
        return;
      }

      if (!mounted) return;

      // Initialize import service
      final booksProvider = context.read<BooksProvider>();
      final shelvesProvider = context.read<ShelvesProvider>();

      _importService = CsvImportService(
        bookService: BookService(),
        booksProvider: booksProvider,
        shelvesProvider: shelvesProvider,
      );

      // Parse CSV and show preview
      final preview = await _importService!.parseCsvFile(file.path!);

      if (!mounted) return;

      setState(() {
        _preview = preview;
        _state = ImportState.preview;
      });
    } on ImportException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to read file: $e';
      });
    }
  }

  Future<void> _startImport() async {
    if (_preview == null || _importService == null) return;

    setState(() {
      _state = ImportState.importing;
      _progress = ImportProgress(
        total: _preview!.totalBooks,
        processed: 0,
        added: 0,
        updated: 0,
        failed: 0,
        skipped: 0,
        currentBookTitle: '',
        results: [],
      );
    });

    // Listen to progress updates
    _progressSubscription = _importService!.progressStream.listen((progress) {
      setState(() {
        _progress = progress;
        if (progress.isComplete) {
          _state = ImportState.complete;
        }
      });
    });

    // Start import
    await _importService!.importBooks(
      _preview!.books,
      importRatings: _importRatings,
      importDates: _importDates,
    );
  }

  void _cancelImport() {
    _importService?.cancelImport();
  }

  void _reset() {
    _progressSubscription?.cancel();
    _importService?.dispose();
    setState(() {
      _state = ImportState.initial;
      _preview = null;
      _progress = null;
      _importService = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from Goodreads'),
      ),
      body: SafeArea(
        child: switch (_state) {
          ImportState.initial => _buildInitialState(),
          ImportState.preview => _buildPreviewState(),
          ImportState.importing => _buildImportingState(),
          ImportState.complete => _buildCompleteState(),
        },
      ),
    );
  }

  Widget _buildInitialState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.upload_file_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Import Your Goodreads Library',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Export your books from Goodreads as a CSV file, then select it here to import.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _pickCsvFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Select CSV File'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to export from Goodreads:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildStep('1', 'Go to goodreads.com and sign in'),
            _buildStep('2', 'Click "My Books" in the navigation'),
            _buildStep('3', 'Click "Import and export" on the left sidebar'),
            _buildStep('4', 'Click "Export Library" to download CSV'),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewState() {
    final preview = _preview!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ready to Import',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    'Total Books',
                    preview.totalBooks.toString(),
                    Icons.menu_book,
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    'Read',
                    preview.readCount.toString(),
                    Icons.check_circle_outline,
                  ),
                  _buildStatRow(
                    'Currently Reading',
                    preview.currentlyReadingCount.toString(),
                    Icons.auto_stories,
                  ),
                  _buildStatRow(
                    'Want to Read',
                    preview.wantToReadCount.toString(),
                    Icons.bookmark_outline,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (preview.customShelvesToCreate.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Shelves to Create',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: preview.customShelvesToCreate.map((name) {
                        return Chip(
                          label: Text(name),
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (preview.booksWithoutIsbn > 0) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${preview.booksWithoutIsbn} books have no ISBN and will be searched by title/author',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Options',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.sync, size: 18, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Books already in your library will be updated',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue.shade700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Import ratings'),
                    value: _importRatings,
                    onChanged: (value) => setState(() => _importRatings = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Import dates (read date, added date)'),
                    value: _importDates,
                    onChanged: (value) => setState(() => _importDates = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _startImport,
            icon: const Icon(Icons.download),
            label: Text('Import ${preview.totalBooks} Books'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _reset,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildImportingState() {
    final progress = _progress!;
    final percent = (progress.progressPercent * 100).toInt();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress.progressPercent,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Importing ${progress.processed} of ${progress.total} books...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (progress.currentBookTitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              progress.currentBookTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressStat(
                'Added',
                progress.added,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildProgressStat(
                'Updated',
                progress.updated,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildProgressStat(
                'Failed',
                progress.failed,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: _cancelImport,
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Import'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildCompleteState() {
    final progress = _progress!;
    final hasFailures = progress.failed > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            progress.isCancelled
                ? Icons.cancel_outlined
                : hasFailures
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle,
            size: 80,
            color: progress.isCancelled
                ? Colors.orange
                : hasFailures
                    ? Colors.orange
                    : Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            progress.isCancelled
                ? 'Import Cancelled'
                : hasFailures
                    ? 'Import Completed with Issues'
                    : 'Import Complete!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildResultRow(
                    'New books added',
                    progress.added,
                    Icons.add_circle,
                    Colors.green,
                  ),
                  const Divider(height: 16),
                  _buildResultRow(
                    'Existing books updated',
                    progress.updated,
                    Icons.sync,
                    Colors.blue,
                  ),
                  if (progress.failed > 0) ...[
                    const Divider(height: 16),
                    _buildResultRow(
                      'Failed to import',
                      progress.failed,
                      Icons.error,
                      Colors.red,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (hasFailures) ...[
            const SizedBox(height: 16),
            Card(
              child: ExpansionTile(
                title: const Text('Failed Books'),
                children: progress.results
                    .where((r) => r.status == ImportStatus.failed)
                    .map((r) => ListTile(
                          dense: true,
                          title: Text(r.goodreadsBook.title),
                          subtitle: Text(r.errorMessage ?? 'Unknown error'),
                        ))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.go('/shelves'),
            icon: const Icon(Icons.auto_stories),
            label: const Text('View Library'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _reset,
            child: const Text('Import Another File'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, int value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
