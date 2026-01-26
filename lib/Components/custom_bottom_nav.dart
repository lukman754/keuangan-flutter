import 'package:flutter/material.dart';
import '../Pages/home.dart';
import '../Pages/category.dart';
import '../Pages/budget.dart';
import '../Pages/transaksi.dart';
import '../Pages/profile.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = const CategoryPage();
        break;
      case 1:
        nextPage = const BudgetPage();
        break;
      case 2:
        nextPage = const HomePage();
        break;
      case 3:
        nextPage = const TransaksiPage();
        break;
      case 4:
        nextPage = const ProfilePage();
        break;
      default:
        return;
    }

    // Navigasi tanpa animasi (Instant)
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => nextPage,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              context,
              0,
              Icons.category_outlined,
              Icons.category,
              'Kategori',
            ),
            _navItem(
              context,
              1,
              Icons.account_balance_wallet_outlined,
              Icons.account_balance_wallet,
              'Budget',
            ),
            _navItem(context, 2, Icons.home_outlined, Icons.home, 'Beranda'),
            _navItem(
              context,
              3,
              Icons.receipt_long_outlined,
              Icons.receipt_long,
              'Transaksi',
            ),
            _navItem(context, 4, Icons.person_outline, Icons.person, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    bool isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(context, index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: AnimatedScale(
                  scale: isActive ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? Colors.white : Colors.grey[400],
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFF1565C0) : Colors.grey[500],
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
