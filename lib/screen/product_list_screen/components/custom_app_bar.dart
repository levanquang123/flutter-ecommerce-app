import 'package:e_commerce_flutter/utility/extensions.dart';
import 'package:flutter/material.dart';
import '../../../widget/app_bar_action_button.dart';
import '../../../widget/custom_search_bar.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(100);

  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (context) {
                return AppBarActionButton(
                  icon: Icons.menu,
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
            Expanded(
              child: CustomSearchBar(
                controller: TextEditingController(),
                onChanged: (val) {
                  context.dataProvider.filterProducts(val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
