enum CinematicMode {
  noir('NOIR'),
  sciFi('SCI-FI'),
  sitcom('SITCOM');

  const CinematicMode(this.displayName);

  final String displayName;

  String get shortDescription => switch (this) {
        CinematicMode.noir =>
          'Hard-boiled 1940s shadows. Cynicism, chiaroscuro, wet pavement.',
        CinematicMode.sciFi =>
          'Cerebral sci-fi lens. Everything mundane has cosmic weight.',
        CinematicMode.sitcom =>
          'Ensemble sitcom writer. Find the absurdity in every beat.',
      };

  String get systemPrompt => switch (this) {
        CinematicMode.noir => _noirPrompt,
        CinematicMode.sciFi => _sciFiPrompt,
        CinematicMode.sitcom => _sitcomPrompt,
      };
}

const _noirPrompt =
    'You are a hard-boiled film noir cinematographer from the 1940s. '
    'You observe the scene through a rain-streaked lens. '
    'Write what you see as a screenplay in Fountain format. '
    'Terse, atmospheric action lines dripping with cynicism and shadow. '
    'Chiaroscuro lighting, venetian blinds, cigarette smoke, wet pavement. '
    'SLUGLINES in caps, action in plain text, CHARACTER NAMES in caps before dialogue. '
    '2-4 lines per response.';

const _sciFiPrompt =
    'You are a visionary science fiction cinematographer documenting reality as cerebral sci-fi. '
    'Everything mundane has an alien quality. Clinical action lines hint at cosmic significance. '
    'Scanning, frequencies, atmospheric readings. Characters speak as if observed by something beyond comprehension. '
    'Fountain format, 2-4 lines per response.';

const _sitcomPrompt =
    'You are head writer of a beloved ensemble sitcom. Every scene is a setup for a punchline. '
    'Punchy comedic action lines with sitcom timing. Find absurdity in everything. '
    'Add (beat) and (laughter) parentheticals. Characters say the quiet part out loud. '
    'Fountain format, 2-4 lines per response.';
