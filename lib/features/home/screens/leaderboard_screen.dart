import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ocevara/core/theme/app_colors.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mock data - this would come from a provider/backend in a real scenario
    final rankings = [
      {'name': 'Amaka', 'impact': '2,450', 'rank': 1, 'image': 'https://images.unsplash.com/photo-1531123897727-8f129e16fd3c?q=80&w=100&h=100&auto=format&fit=crop'},
      {'name': 'James Wilson', 'impact': '1,820', 'rank': 2, 'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=100&h=100&auto=format&fit=crop'},
      {'name': 'Sarah Chen', 'impact': '1,650', 'rank': 3, 'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=100&h=100&auto=format&fit=crop'},
      {'name': 'David Okoro', 'impact': '1,420', 'rank': 4, 'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=100&h=100&auto=format&fit=crop'},
      {'name': 'Chidi Azikiwe', 'impact': '1,280', 'rank': 5, 'image': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=100&h=100&auto=format&fit=crop'},
      {'name': 'Grace Mensah', 'impact': '1,150', 'rank': 6, 'image': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=100&h=100&auto=format&fit=crop'},
      {'name': 'Austin James', 'impact': '980', 'rank': 12, 'image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=100&h=100&auto=format&fit=crop'},
    ];

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(context),
      body: Stack(
        children: [
          // Semi-transparent background image
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/sign-up.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.getTextPrimary(context)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Leaderboard',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top 3 Podium Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Rank 2
                      _buildPodiumItem(rankings[1], 100, Colors.grey.shade400, context),
                      const SizedBox(width: 16),
                      // Rank 1 (Amaka)
                      _buildPodiumItem(rankings[0], 130, const Color(0xFFFFD700), context, isFirst: true),
                      const SizedBox(width: 16),
                      // Rank 3
                      _buildPodiumItem(rankings[2], 90, const Color(0xFFCD7F32), context),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Rankings List
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: rankings.length - 3,
                      separatorBuilder: (context, index) => Divider(color: Colors.grey.withOpacity(0.1)),
                      itemBuilder: (context, index) {
                        final user = rankings[index + 3];
                        final isCurrentUser = user['rank'] == 12;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? AppColors.primaryTeal.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${user['rank']}',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(width: 16),
                              CircleAvatar(
                                radius: 22,
                                backgroundImage: NetworkImage(user['image'] as String),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  '${user['name']}${isCurrentUser ? ' (You)' : ''}',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ),
                              Text(
                                '${user['impact']} pts',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, double height, Color crownColor, BuildContext context, {bool isFirst = false}) {
    return Column(
      children: [
        if (isFirst)
          Icon(Icons.workspace_premium, color: crownColor, size: 32)
        else
          const SizedBox(height: 32),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
             Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: crownColor, width: 2),
              ),
              child: CircleAvatar(
                radius: isFirst ? 45 : 35,
                backgroundImage: NetworkImage(user['image'] as String),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: crownColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${user['rank']}',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user['name'] as String,
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(context),
            fontSize: isFirst ? 16 : 14,
          ),
        ),
        Text(
          '${user['impact']} pts',
          style: GoogleFonts.lato(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
