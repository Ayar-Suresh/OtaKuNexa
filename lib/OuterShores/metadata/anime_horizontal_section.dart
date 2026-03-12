import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakunexa/OuterShores/model/metadate_model.dart';
// ✅ Import your service here
import 'package:otakunexa/OuterShores/teleg/teleg_service.dart';
import 'package:otakunexa/pages/Main/anime_about_page.dart';
import 'package:otakunexa/pages/Main/search_screen.dart';
import 'package:shimmer/shimmer.dart';

class AnimeHorizontalSection extends StatefulWidget {
  final String title;
  final List<AnimeModel>? animeList;
  final bool isLoading;

  const AnimeHorizontalSection({
    super.key,
    required this.title,
    this.animeList,
    this.isLoading = false,
  });

  @override
  State<AnimeHorizontalSection> createState() => _AnimeHorizontalSectionState();
}

class _AnimeHorizontalSectionState extends State<AnimeHorizontalSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        SizedBox(height: 6.h),
        SizedBox(
          height: 240.h,
          child: widget.isLoading ? _buildShimmerList() : _buildAnimeList(),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 17.5.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.3),
                  width: 1.w,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    "Search",
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.deepPurple,
                    size: 11.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeList() {
    if (widget.animeList == null || widget.animeList!.isEmpty) {
      return const Center(
        child: Text("No Data Available", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      itemCount: widget.animeList!.length,
      itemBuilder: (context, index) {
        final anime = widget.animeList![index];
        return _buildAnimeCard(context, anime);
      },
    );
  }

  Widget _buildAnimeCard(BuildContext context, AnimeModel anime) {
    // 🧠 LOGIC: We fetch availability for EACH card individually
    return FutureBuilder<Map<String, dynamic>?>(
      future: AnimeDownloadService.checkAvailability(
        anime.data.malId.toString(),
      ),
      builder: (context, snapshot) {
        // 1. Determine Status & Language
        bool isAvailable = false;
        String language = "🌍 Multi-Lang"; // Default fallback
        String availabilityLabel = "UNAVAILABLE";
        bool isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (snapshot.hasData && snapshot.data != null) {
          isAvailable = true;
          availabilityLabel = "AVAILABLE";
          var rawData = snapshot
              .data!['data']; // This is the Anime Object (e.g. "Haikyuu")

          if (rawData != null && rawData['seasons'] != null) {
            Map<String, dynamic> seasons = rawData['seasons'];

            // --- 🔍 FIX: LOOK INSIDE SEASONS FOR LANGUAGE ---
            // We iterate through seasons to find the first one with a 'language' tag
            for (var seasonKey in seasons.keys) {
              var seasonData = seasons[seasonKey];
              if (seasonData['language'] != null) {
                language = seasonData['language'].toString();
                // If it looks like "English/Sub", make it cleaner "Sub | Dub" (Optional)
                language = language.replaceAll("/", " | ");
                break; // Found one, stop looking
              }
            }
          }
        }

        return Container(
          width: 145.w,
          margin: EdgeInsets.only(right: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Stack(
                  children: [
                    _buildCachedImage(
                      context,
                      anime.data.images.jpg.largeImageUrl.isNotEmpty
                          ? anime.data.images.jpg.largeImageUrl
                          : anime.data.images.jpg.imageUrl,
                      anime,
                    ),

                    // --- 🎯 LANGUAGE BADGE (Top Left) ---
                    // Shows only if available, otherwise hides or shows default
                    if (isAvailable && !isLoading)
                      Positioned(
                        top: 6.h,
                        left: 6.w,
                        child: _buildBadge(language, Colors.black87),
                      ),

                    // --- 🎯 SCORE BADGE (Top Right) ---
                    Positioned(
                      top: 6.h,
                      right: 6.w,
                      child: _buildBadge(
                        anime.data.score > 0 ? "★ ${anime.data.score}" : "N/A",
                        Colors.deepPurpleAccent,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6.h),
              _buildSingleLineTitle(anime.data.titleEnglish),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Type (TV/Movie)
                  Text(
                    anime.data.type ?? "Anime",
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),

                  SizedBox(width: 4.w),

                  // --- 🎯 AVAILABILITY BADGE (Bottom Right) ---
                  Padding(
                    padding: EdgeInsets.only(right: 7.w),
                    child: isLoading
                        ? SizedBox(
                            width: 10.w,
                            height: 10.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey,
                            ),
                          )
                        : _buildAvailabilityBadge(
                            isAvailable,
                            label: availabilityLabel,
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Update this helper function to accept dynamic label ---
  Widget _buildAvailabilityBadge(
    bool isAvailable, {
    String label = "AVAILABLE",
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFF00E676).withOpacity(0.2)
            : Colors.grey[900],
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: isAvailable ? const Color(0xFF00E676) : Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Text(
        isAvailable ? label : "UNAVAILABLE", // Shows "25 EPS" or "AVAILABLE"
        style: TextStyle(
          color: isAvailable ? const Color(0xFF00E676) : Colors.grey[500],
          fontSize: 8.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSingleLineTitle(String text) {
    return SizedBox(
      height: 18.h,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCachedImage(
    BuildContext context,
    String imageUrl,
    AnimeModel selectedAnime,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeAboutPage(selectedAnime: selectedAnime),
          ),
        );
      },
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 190.h,
        width: 140.w,
        fit: BoxFit.fill,
        placeholder: (_, __) => _buildImagePlaceholder(),
        errorWidget: (c, u, e) => _buildPermanentPlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 190.h,
      width: 140.w,
      color: Colors.grey[800],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.w,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPermanentPlaceholder() {
    return Container(
      height: 190.h,
      width: 140.w,
      color: Colors.grey[800],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey[600], size: 40.sp),
          SizedBox(height: 8.h),
          Text(
            'Image Not Available',
            style: TextStyle(color: Colors.grey[600], fontSize: 10.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      itemCount: 6,
      itemBuilder: (_, __) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      width: 140.w,
      margin: EdgeInsets.only(right: 10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[700]!,
            child: Container(
              height: 190.h,
              width: 140.w,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[700]!,
            child: Container(
              height: 12.h,
              width: 120.w,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 6.h),
          Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[700]!,
            child: Container(
              height: 10.h,
              width: 60.w,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }
}
