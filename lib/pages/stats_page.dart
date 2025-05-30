import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Define the custom ScrollBehavior to remove the overscroll glow
class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child; // This effectively removes the glow
  }
}

class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> rows = [];
  int selectedGraphIndex = 0;

  final List<String> graphOptions = [
    'Under/Post Graduates',
    'Employment',
    'Job Sectors',
    'Overseas / Local',
    'WFH / WFO',
  ];

  final List<Color> _sectionColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final res = await supabase.from('userdata').select();
    if (mounted) {
      setState(() {
        rows = List<Map<String, dynamic>>.from(res as List);
      });
    }
  }

  Map<String, int> _count(String key, List<dynamic> bins) {
    final m = {for (var b in bins) b.toString(): 0};
    for (var r in rows) {
      final v = r[key];
      final k = (v == null) ? 'Unknown' : v.toString();
      // Ensure that if a key comes from data that wasn't in bins, it's still counted.
      // However, the current logic initializes with bins, so only predefined bins (and 'Unknown' if v is null) are counted.
      // If 'Unknown' is not in bins and v is null, it would cause an issue.
      // Let's refine this slightly to handle 'Unknown' more robustly if it's not in bins.
      if (m.containsKey(k)) {
        m[k] = (m[k] ?? 0) + 1;
      } else if (k == 'Unknown') { // Handle 'Unknown' if not explicitly in bins
        m[k] = (m[k] ?? 0) + 1;
      }
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    if (rows.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          elevation: 0,
          backgroundColor: scaffoldBackgroundColor,
          surfaceTintColor: scaffoldBackgroundColor, // Ensure no M3 tinting
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Prepare counts...
    final upCounts = {
      'Undergrad': rows.where((r) => r['is_undergrad'] == true).length,
      'Postgrad': rows.where((r) => r['is_undergrad'] == false).length,
    };
    final post = rows.where((r) => r['is_undergrad'] == false).toList();
    final empCounts = {
      'Employed': post.where((r) =>
              (r['job_sector'] != null && r['job_sector'] != 'Unknown'))
          .length,
      'Unemployed': post.where((r) =>
              (r['job_sector'] == null || r['job_sector'] == 'Unknown'))
          .length,
    };
    final sectorCounts = _count('job_sector', [
      'Technology & Digital Services',
      'Engineering',
      'Healthcare',
      'Financial Services',
      'Business & Management',
      'Unknown' // Ensure 'Unknown' is a bin if you expect it from _count
    ]);
    final ovCounts = {
      'Overseas': rows.where((r) => r['work_overseas'] == true).length,
      'Local': rows.where((r) => r['work_overseas'] == false).length,
    };
    // Make sure the bins for wmCounts include 'Unknown' if it can appear from _count
    final wmCounts = _count('work_mode', ['Office', 'Hybrid', 'Remote', 'Unknown']);


    Map<String, int> counts;
    String title;
    switch (selectedGraphIndex) {
      case 0:
        counts = upCounts;
        title = 'Undergrad vs Postgrad';
        break;
      case 1:
        counts = empCounts;
        title = 'Postgraduate: Employed vs Unemployed';
        break;
      case 2:
        counts = sectorCounts;
        title = 'Job Sector Popularity';
        break;
      case 3:
        counts = ovCounts;
        title = 'Overseas vs Local';
        break;
      case 4:
        counts = wmCounts;
        title = 'Work Mode (Office/Hybrid/Remote)';
        break;
      default:
        counts = upCounts;
        title = 'Undergrad vs Postgrad';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: scaffoldBackgroundColor,
        surfaceTintColor: scaffoldBackgroundColor, // Ensure no M3 tinting
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Card ──────────────────────────────────────────────────────
            Expanded(
              flex: 7,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Title
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                title,
                                style:
                                    Theme.of(context).textTheme.titleLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),

                        // Chart
                        Expanded(
                          flex: 5,
                          child: _ResponsivePieChart(
                            counts: counts,
                            colors: _sectionColors,
                          ),
                        ),

                        const Spacer(flex: 1),

                        // Legend
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: List.generate(
                                counts.keys.length,
                                (i) {
                                  final label = counts.keys.elementAt(i);
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        color: _sectionColors[
                                            i % _sectionColors.length],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(label),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─── Bottom Picker ─────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  const Spacer(flex: 1), // push content down
                  const Text(
                    'Graph:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4), // tighten gap
                  Flexible(
                    flex: 2, // give picker a controlled share
                    child: ScrollConfiguration(
                      behavior: NoGlowScrollBehavior(), // Apply custom scroll behavior
                      child: CupertinoPicker(
                        itemExtent: 32,
                        onSelectedItemChanged: (i) =>
                            setState(() => selectedGraphIndex = i),
                        children: graphOptions
                            .map((o) => Center(child: Text(o)))
                            .toList(),
                      ),
                    ),
                  ),
                  const Spacer(flex: 1), // pull picker up further
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pie chart that always fills the space its parent Expanded grants it.
class _ResponsivePieChart extends StatelessWidget {
  final Map<String, int> counts;
  final List<Color> colors;

  const _ResponsivePieChart({
    Key? key,
    required this.counts,
    required this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = min(constraints.maxWidth, constraints.maxHeight);
      final sections = <PieChartSectionData>[];
      final labels = counts.keys.toList();

      // Filter out keys with zero or null counts before creating sections
      final validLabels = labels.where((label) => (counts[label] ?? 0) > 0).toList();

      for (var i = 0; i < validLabels.length; i++) {
        final label = validLabels[i];
        final value = counts[label]!.toDouble();
        sections.add(PieChartSectionData(
          value: value,
          color: colors[i % colors.length],
          title: value.toInt().toString(),
          radius: size * 0.4,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ));
      }

      if (sections.isEmpty) {
        return Center(child: Text('No data to display', style: Theme.of(context).textTheme.bodySmall));
      }

      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: size * 0.15,
              sectionsSpace: 2,
            ),
          ),
        ),
      );
    });
  }
}