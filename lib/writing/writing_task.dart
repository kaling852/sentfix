enum WritingTask { fixEnglish, concise }

extension WritingTaskLabel on WritingTask {
  String get label => switch (this) {
    WritingTask.fixEnglish => 'Fix my English',
    WritingTask.concise => 'Rewrite to be concise',
  };

  String get shortLabel => switch (this) {
    WritingTask.fixEnglish => 'Fix English',
    WritingTask.concise => 'Concise',
  };
}
