import 'package:cloudotp/Utils/cache_util.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../Utils/utils.dart';
import '../../generated/l10n.dart';

class WebDavBackupsBottomSheet extends StatefulWidget {
  const WebDavBackupsBottomSheet({
    super.key,
    required this.files,
    required this.onSelected,
  });

  final List<WebDavFile> files;
  final Function(WebDavFile) onSelected;

  @override
  WebDavBackupsBottomSheetState createState() =>
      WebDavBackupsBottomSheetState();
}

class WebDavBackupsBottomSheetState extends State<WebDavBackupsBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var mainBody = Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.vertical(
            top: const Radius.circular(20),
            bottom: ResponsiveUtil.isLandscape()
                ? const Radius.circular(20)
                : Radius.zero),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildHeader(),
          Flexible(
            child: _buildButtons(),
          ),
        ],
      ),
    );
    return ResponsiveUtil.isLandscape() ? Center(child: mainBody) : mainBody;
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      alignment: Alignment.center,
      child: Text(
        S.current.webDavBackupFiles,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  _buildButtons() {
    return ListView.builder(
      shrinkWrap: true,
      itemBuilder: (context, index) => _buildItem(widget.files[index]),
      itemCount: widget.files.length,
    );
  }

  _buildItem(WebDavFile file) {
    String size =
        CacheUtil.renderSize(file.size?.toDouble() ?? 0, fractionDigits: 0);
    String time =
        Utils.formatTimestamp(file.mTime?.millisecondsSinceEpoch ?? 0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.onSelected(file);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                width: 0.5,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_download_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name ?? "",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      "$time    $size",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
