import 'package:flutter/material.dart';
import '../widgets/milo_logo.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  bool _isDeveloperExpanded = false;
  bool _isMiloExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF667EEA),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'About Milo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                      Color(0xFF9575CD),
                    ],
                  ),
                ),
                child: const Center(
                  child: MiloLogo(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progressive Overload Philosophy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inspired by the legendary strength of Milo of Croton',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Developer Accordion
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.grey.shade50],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.code, color: Color(0xFF667EEA)),
                      ),
                      title: const Text(
                        'Developer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      initiallyExpanded: _isDeveloperExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _isDeveloperExpanded = expanded;
                        });
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Developer Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'This progressive overload app was developed using Flutter, inspired by the ancient Greek philosophy of gradual improvement and strength building.',
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Features:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('• Time-based and unit-based task tracking'),
                              Text('• Progressive overload methodology'),
                              Text('• Local data persistence'),
                              Text('• Customizable units and templates'),
                              Text('• Greek mythology inspired design'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Milo of Croton Accordion
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.grey.shade50],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      title: const Text(
                        'Milo of Croton',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      initiallyExpanded: _isMiloExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _isMiloExpanded = expanded;
                        });
                        if (expanded) {
                          _navigateToMiloStory();
                        }
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Tap to learn about the legendary Milo of Croton and his progressive training methods...',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMiloStory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const MiloStoryPage()));
  }
}

class MiloStoryPage extends StatelessWidget {
  const MiloStoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Milo of Croton'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The Legend of Milo of Croton',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildStorySection(
              title: 'The Beginning',
              content:
                  'Milo of Croton (6th century BC) was a legendary Greek wrestler from the city of Croton in southern Italy. He is considered one of the greatest athletes of ancient Greece and won the wrestling competition at the Olympic Games six times.',
              imagePlaceholder: 'Ancient Greek athlete training',
            ),

            _buildStorySection(
              title: 'The Progressive Method',
              content:
                  'The most famous story about Milo tells of his training method. As a young man, he began carrying a newborn calf on his shoulders every day. As the calf grew larger and heavier, Milo\'s strength increased proportionally.',
              imagePlaceholder: 'Young Milo carrying a small calf',
            ),

            _buildStorySection(
              title: 'The Growing Challenge',
              content:
                  'Day by day, week by week, month by month, the calf grew heavier. But because the increase was gradual, Milo\'s body adapted to the growing weight. His muscles, bones, and cardiovascular system all strengthened progressively.',
              imagePlaceholder: 'Milo with a growing calf over time',
            ),

            _buildStorySection(
              title: 'The Full-Grown Bull',
              content:
                  'Eventually, Milo was carrying a full-grown bull on his shoulders - a feat that would have been impossible if attempted suddenly, but achievable through consistent, progressive overload.',
              imagePlaceholder: 'Milo carrying a full-grown bull',
            ),

            _buildStorySection(
              title: 'The Philosophy',
              content:
                  'This story embodies the principle of progressive overload - the gradual increase of stress placed upon the body during exercise training. It\'s the foundation of all strength and conditioning programs.',
              imagePlaceholder: 'Ancient Greek gymnasium',
            ),

            _buildStorySection(
              title: 'Modern Application',
              content:
                  'Today, Milo\'s method is applied not just to physical training, but to any skill or habit we want to develop. By starting small and gradually increasing the challenge, we can achieve remarkable results.',
              imagePlaceholder: 'Modern progressive training',
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '"Excellence is not an act, but a habit. We are what we repeatedly do."',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '- Aristotle',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorySection({
    required String title,
    required String content,
    required String imagePlaceholder,
  }) {
    // Map placeholder text to actual image files
    String? imagePath = _getImagePath(imagePlaceholder);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Actual image or placeholder
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imagePath != null
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder(imagePlaceholder);
                    },
                  )
                : _buildPlaceholder(imagePlaceholder),
          ),
        ),

        const SizedBox(height: 12),
        Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 24),
      ],
    );
  }

  String? _getImagePath(String placeholder) {
    switch (placeholder.toLowerCase()) {
      case 'ancient greek athlete training':
        return 'assets/images/story/Ancient Greek athlete training.jpg';
      case 'young milo carrying a small calf':
        return 'assets/images/story/young milo carrying a small calf.jpg';
      case 'milo with a growing calf over time':
        return 'assets/images/story/Milo with a growing calf over time.jpg';
      default:
        return null; // Return null for placeholders without matching images
    }
  }

  Widget _buildPlaceholder(String text) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
