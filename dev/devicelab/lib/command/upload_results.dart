// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';

import '../framework/cocoon.dart';

class UploadResultsCommand extends Command<void> {
  UploadResultsCommand() {
    argParser.addOption('results-file', help: 'Test results JSON to upload to Cocoon.');
    argParser.addOption(
      'service-account-token-file',
      help: 'Authentication token for uploading results.',
    );
    argParser.addOption('test-flaky', help: 'Flag to show whether the test is flaky');
    argParser.addOption(
      'git-branch',
      help: '[Flutter infrastructure] Git branch of the current commit. LUCI\n'
          'checkouts run in detached HEAD state, so the branch must be passed.',
    );
    argParser.addOption('luci-builder', help: '[Flutter infrastructure] Name of the LUCI builder being run on.');
  }

  @override
  String get name => 'upload-metrics';

  @override
  String get description => '[Flutter infrastructure] Upload results data to Cocoon';

  @override
  Future<void> run() async {
    final String? resultsPath = argResults!['results-file'] as String?;
    final String? serviceAccountTokenFile = argResults!['service-account-token-file'] as String?;
    final bool? isTestFlaky = argResults!['test-flaky'] as bool?;
    final String? gitBranch = argResults!['git-branch'] as String?;
    final String? builderName = argResults!['luci-builder'] as String?;

    final Cocoon cocoon = Cocoon(serviceAccountTokenPath: serviceAccountTokenFile);
    return cocoon.sendResultsPath(
        resultsPath: resultsPath, isTestFlaky: isTestFlaky, gitBranch: gitBranch, builderName: builderName);
  }
}
