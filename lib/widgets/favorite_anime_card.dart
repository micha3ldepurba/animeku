import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/routes.dart';

class FavoriteAnimeCard extends StatelessWidget {
  final String id;
  final String title;
  final String genre;
  final String rating;
  final String imagePath;

  const FavoriteAnimeCard({
    super.key,
    required this.id,
    required this.title,
    required this.genre,
    required this.rating,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => {context.push('${AppRoutes.details}/$id')},
      child: Card (
          margin: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.01,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          color: const Color(0xFF0b395e),
          elevation: 5,
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    child: imagePath.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: imagePath,
                      width: screenWidth * 0.2,
                      height: screenHeight * 0.12,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.white.withValues(alpha: 0.1),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.white.withValues(alpha:0.1),
                        child: const Icon(Icons.broken_image),
                      ),
                    )
                        : Container(
                      width: screenWidth * 0.2,
                      height: screenHeight * 0.12,
                      color: Colors.white.withValues(alpha: 0.1),
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),

                  // content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          genre,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: screenWidth * 0.04),
                            SizedBox(width: screenWidth * 0.01),
                            Text(
                              rating,
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
          )
      ),
    );
  }
}