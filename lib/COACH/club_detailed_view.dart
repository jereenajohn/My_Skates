import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_skates/COACH/club_followers_page.dart';
import 'package:my_skates/COACH/club_rating_approval.dart';
import 'package:my_skates/COACH/club_reviews_viewpage.dart';
import 'package:my_skates/COACH/coach_add_events.dart';
import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class RatingData {
  final int id;
  final int rating;
  final String review;
  final String userName;
  final String? userImage;
  final String createdAt;
  final String approvalStatus;

  RatingData({
    required this.id,
    required this.rating,
    required this.review,
    required this.userName,
    this.userImage,
    required this.createdAt,
    required this.approvalStatus,
  });

  factory RatingData.fromJson(Map<String, dynamic> json) {
    return RatingData(
      id: json['id'] ?? 0,
      rating: json['rating'] ?? 0,
      review: json['review'] ?? '',
      userName: json['user_name'] ?? 'User ${json['user']}',
      userImage: json['user_image'],
      createdAt: json['created_at'] ?? '',
      approvalStatus: json['approval_status'] ?? 'pending',
    );
  }
}

class UserRating {
  final int id;
  final int rating;
  final String review;

  UserRating({required this.id, required this.rating, required this.review});

  factory UserRating.fromJson(Map<String, dynamic> json) {
    return UserRating(
      id: json['id'] ?? 0,
      rating: json['rating'] ?? 0,
      review: json['review'] ?? '',
    );
  }
}

class ClubView extends StatefulWidget {
  final int clubid;
  final bool isApproved;
  const ClubView({super.key, required this.clubid, this.isApproved = false});

  @override
  State<ClubView> createState() => _ClubViewState();
}

class _ClubViewState extends State<ClubView> {
  Map<String, dynamic>? club;
  bool loading = true;
  List<dynamic> feedPosts = [];
  bool isFeedLoading = true;
  int followersCount = 0;

  bool _hasUserRated = false;
  UserRating? _userRating;
  bool _isLoadingRating = true;
  List<RatingData> _recentRatings = [];
  double _averageRating = 0.0;

  bool _isCoach = false;
  int? _currentUserId;

  bool _hasSentFollowRequest = false;
  bool _isFollowing = false;
  bool _isLoadingFollowStatus = true;

  String? _clubRequestStatus;
  bool _isClubLoading = true;

  Map<int, bool> _likedPosts = {};
  Map<int, int> _likeCounts = {};

  bool _isLoadingLikes = false;

  Map<int, List<dynamic>> _postComments = {};
  Map<int, int> _commentCounts = {};
  bool _isLoadingComments = false;
  int? _expandedCommentPostId;

  Map<int, bool> _repostedPosts = {};
  Map<int, int> _repostCounts = {};

  bool get _canViewFullClubPage {
    return _isCoach || widget.isApproved || _clubRequestStatus == "approved";
  }

  bool get _isMyClub {
    final c = club ?? {};

    final dynamic owner =
        c["user"] ?? c["created_by"] ?? c["owner"] ?? c["coach"] ?? c["admin"];

    final int? ownerId = owner is int
        ? owner
        : int.tryParse(owner?.toString() ?? "");
    return ownerId != null &&
        _currentUserId != null &&
        ownerId == _currentUserId;
  }

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    fetchClubDetails();
    fetchClubEvents();
    fetchFollowersCount();
    _fetchClubRequestStatus();
    fetchClubFeeds();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserRating();
    });

    print("Club ID: ${widget.clubid}");
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  Future<void> _refreshClubView() async {
    setState(() {
      // loading = true;
      isFeedLoading = true;
      isEventsLoading = true;
    });

    try {
      await Future.wait([
        fetchClubDetails(),
        fetchClubEvents(),
        fetchFollowersCount(),
        _fetchClubRequestStatus(),
        fetchClubFeeds(),
        _checkUserRating(),
      ]);

      print("Club view refreshed successfully");
    } catch (e) {
      print("Error refreshing club view: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to refresh: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          isFeedLoading = false;
          isEventsLoading = false;
        });
      }
    }
  }

  Future<void> _fetchClubRequestStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) return;

      final response = await http.get(
        Uri.parse("$api/api/myskates/club/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> clubs = jsonDecode(response.body);

        final thisClub = clubs.firstWhere(
          (c) => c['id'] == widget.clubid,
          orElse: () => null,
        );

        if (thisClub != null) {
          setState(() {
            _clubRequestStatus = thisClub['approval_status'];
          });
        }
      }
    } catch (e) {
      print("Error fetching club request status: $e");
    } finally {
      setState(() {
        _isClubLoading = false;
      });
    }
  }

  Future<void> _sendClubJoinRequest() async {
    final token = await getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('$api/api/myskates/club/join/${widget.clubid}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _clubRequestStatus = 'pending';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Join request sent successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("CLUB JOIN ERROR: $e");
    }
  }

  Future<void> _leaveClub() async {
    final token = await getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('$api/api/myskates/club/leave/${widget.clubid}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _clubRequestStatus = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Left club successfully"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("CLUB LEAVE ERROR: $e");
    }
  }

  Future<bool> _confirmLeaveClub() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Leave Club?",
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                "Are you sure you want to leave this club?",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text(
                    "Leave",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildClubActionButton() {
    String buttonText;
    Color buttonColor;
    VoidCallback? onTap;

    if (_clubRequestStatus == 'approved') {
      buttonText = "Joined";
      buttonColor = Colors.redAccent;
      onTap = () async {
        final confirmed = await _confirmLeaveClub();
        if (confirmed) {
          _leaveClub();
        }
      };
    } else if (_clubRequestStatus == 'pending') {
      buttonText = "Requested";
      buttonColor = Colors.orange;
      onTap = null;
    } else {
      buttonText = "Join Club";
      buttonColor = Colors.teal;
      onTap = _sendClubJoinRequest;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _checkFollowStatus() async {
    setState(() {
      _isLoadingFollowStatus = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null || userId == null) {
        setState(() {
          _isLoadingFollowStatus = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse("$api/api/myskates/user/follow/clubs/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("Follow status response: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> followedClubs = jsonDecode(response.body);

        final clubFollow = followedClubs.firstWhere(
          (fc) => fc['club'] == widget.clubid,
          orElse: () => null,
        );

        if (clubFollow != null) {
          setState(() {
            _hasSentFollowRequest = true;
            _isFollowing = clubFollow['status'] == 'approved';
          });
        }
      }
    } catch (e) {
      print("Error checking follow status: $e");
    } finally {
      setState(() {
        _isLoadingFollowStatus = false;
      });
    }
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt("id");
    final userType = prefs.getString("user_type");

    setState(() {
      _isCoach = userType == 'coach';
      print("User is coach: $_isCoach");
    });
  }

  Future<void> _checkUserRating() async {
    setState(() {
      _isLoadingRating = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse("$api/api/myskates/club/rating/${widget.clubid}/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("responsee ${response.body}");
      if (response.statusCode == 200) {
        final List<dynamic> ratings = jsonDecode(response.body);

        final approvedRatings = ratings
            .where((r) => r['approval_status'] == 'approved')
            .toList();

        if (approvedRatings.isNotEmpty) {
          double total = 0;
          for (var rating in approvedRatings) {
            total += rating['rating'] ?? 0;
          }
          _averageRating = total / approvedRatings.length;
        } else {
          _averageRating = 0.0;
        }

        final ratingsToDisplay = ratings
            .where((r) => r['approval_status'] == 'approved')
            .toList();

        print(
          "Displaying ${ratingsToDisplay.length} approved ratings out of ${ratings.length} total",
        );

        List<RatingData> ratingDataList = [];

        for (var rating in ratingsToDisplay) {
          String firstName = rating['user_first_name'] ?? '';
          String lastName = rating['user_last_name'] ?? '';
          String userName = '';

          if (firstName.isNotEmpty && lastName.isNotEmpty) {
            userName = '$firstName $lastName';
          } else if (firstName.isNotEmpty) {
            userName = firstName;
          } else if (lastName.isNotEmpty) {
            userName = lastName;
          } else {
            userName = 'User ${rating['user']}';
          }

          String? userImage = rating['profile'];
          if (userImage != null && userImage.isNotEmpty) {
            if (!userImage.startsWith('http')) {
              userImage = userImage.startsWith('/')
                  ? "$api$userImage"
                  : "$api/$userImage";
            }
          }

          ratingDataList.add(
            RatingData(
              id: rating['id'],
              rating: rating['rating'],
              review: rating['review'] ?? '',
              userName: userName,
              userImage: userImage,
              createdAt: rating['created_at'] ?? '',
              approvalStatus: rating['approval_status'] ?? 'pending',
            ),
          );
        }

        setState(() {
          _recentRatings = ratingDataList;
        });

        final userRating = ratings.firstWhere(
          (rating) => rating['user'] == userId,
          orElse: () => null,
        );

        if (userRating != null) {
          setState(() {
            _hasUserRated = true;
            _userRating = UserRating(
              id: userRating['id'],
              rating: userRating['rating'],
              review: userRating['review'] ?? '',
            );
          });

          if (userRating['approval_status'] == 'pending') {
            _showPendingRatingMessage();
          }
        } else if (!_isCoach) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showRatingPopup();
            }
          });
        }
      }
    } catch (e) {
      print("Error checking rating: $e");
    } finally {
      setState(() {
        _isLoadingRating = false;
      });
    }
  }

  void _showPendingRatingMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.orange,
        content: Text(
          "Your rating is pending approval from the club admin",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showRatingPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RatingPopup(
          clubId: widget.clubid,
          onSubmit: (rating, review) async {
            await _submitRating(rating, review);
          },
          onSkip: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _submitRating(int rating, String review) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null || userId == null) return;

      final url = Uri.parse("$api/api/myskates/club/rating/${widget.clubid}/");

      final requestBody = {
        "club": widget.clubid,
        "rating": rating,
        "review": review,
        "user": userId,
      };

      print("Sending rating request: ${jsonEncode(requestBody)}");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      print("Submit Rating Response: ${response.statusCode}");
      print("Submit Rating Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text(
              "Thank you for your rating!",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );

        _checkUserRating();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit rating: ${response.body}")),
        );
      }
    } catch (e) {
      print("Submit Rating Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showUpdateRatingDialog() {
    if (_userRating == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RatingPopup(
          clubId: widget.clubid,
          initialRating: _userRating!.rating,
          initialReview: _userRating!.review,
          isUpdate: true,
          onSubmit: (rating, review) async {
            await _updateRating(rating, review);
          },
          onSkip: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _updateRating(int rating, String review) async {
    if (_userRating == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null) return;

      final url = Uri.parse(
        "$api/api/myskates/club/rating/update/${_userRating!.id}/",
      );

      final requestBody = {
        "club": widget.clubid,
        "rating": rating,
        "review": review,
        "user": userId,
      };

      print("Sending update rating request: ${jsonEncode(requestBody)}");

      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      print("Update Rating Response: ${response.statusCode}");
      print("Update Rating Body: ${response.body}");

      if (response.statusCode == 200) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text(
              "Rating updated successfully!",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );

        _checkUserRating();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update rating: ${response.body}")),
        );
      }
    } catch (e) {
      print("Update Rating Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> fetchFollowersCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) return;

      final res = await http.get(
        Uri.parse("$api/api/myskates/club/${widget.clubid}/followers/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          followersCount = body["followers_count"] ?? 0;
        });
      }
    } catch (e) {
      // fail silently
    }
  }

  Future<void> fetchClubFeeds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null) {
        print("No token found");
        setState(() {
          isFeedLoading = false;
        });
        return;
      }

      final url = Uri.parse("$api/api/myskates/club/${widget.clubid}/feeds/");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        print("FEED RAW RESPONSE: $data");

        if (data is Map &&
            data['status'] == 'success' &&
            data['data'] != null) {
          final postsData = data['data'];

          if (postsData is List) {
            // Parse like and comment data
            Map<int, bool> likedMap = {};
            Map<int, int> likeCountMap = {};
            Map<int, int> commentCountMap = {};

            for (var post in postsData) {
              int postId = post['id'] ?? 0;

              // Get total likes
              int totalLikes = post['total_likes'] ?? 0;
              likeCountMap[postId] = totalLikes;

              // Get total comments
              int totalComments = post['total_comments'] ?? 0;
              commentCountMap[postId] = totalComments;

              // Check if current user liked this post
              bool userLiked = false;

              if (post['user_liked'] != null) {
                userLiked = post['user_liked'] == true;
              } else if (post['liked_by'] != null && post['liked_by'] is List) {
                userLiked = (post['liked_by'] as List).contains(userId);
              }

              likedMap[postId] = userLiked;
            }

            setState(() {
              feedPosts = postsData;
              _likedPosts = likedMap;
              _likeCounts = likeCountMap;
              _commentCounts = commentCountMap;
              isFeedLoading = false;
            });
            print("Feed data fetched: ${postsData.length} posts");

            if (postsData.isNotEmpty) {
              print("FIRST POST STRUCTURE: ${postsData[0]}");
            }
          } else {
            setState(() {
              feedPosts = [];
              isFeedLoading = false;
            });
            print("Posts data is not a List: ${postsData.runtimeType}");
          }
        } else {
          print("Unexpected response format: $data");
          setState(() {
            feedPosts = [];
            isFeedLoading = false;
          });
        }
      } else {
        print("GET Error: ${response.statusCode}");
        print(response.body);
        setState(() {
          isFeedLoading = false;
        });
      }
    } catch (e) {
      print("GET Exception: $e");
      setState(() {
        isFeedLoading = false;
      });
    }
  }

  // UPDATED: Support multiple images
  Future<void> submitFeedPost(
    String title,
    String description,
    List<XFile?>? imageFiles,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login to post")));
        return;
      }

      print("Submitting feed post with ${imageFiles?.length ?? 0} images");

      final url = Uri.parse("$api/api/myskates/club/feed/create/");

      final request = http.MultipartRequest("POST", url);

      request.headers["Authorization"] = "Bearer $token";
      request.headers["Accept"] = "application/json";

      if (title.isNotEmpty) {
        request.fields["title"] = title;
      }

      if (description.isNotEmpty) {
        request.fields["description"] = description;
      }

      request.fields["club"] = widget.clubid.toString();

      // Add multiple images
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (var imageFile in imageFiles) {
          if (imageFile != null) {
            final file = File(imageFile.path);
            if (await file.exists()) {
              print("File exists: ${file.lengthSync()} bytes");
              request.files.add(
                await http.MultipartFile.fromPath("images", imageFile.path),
              );
            } else {
              print("File does not exist: ${imageFile.path}");
            }
          }
        }
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print("Feed post response status: ${response.statusCode}");
      print("Feed post response body: $responseData");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text(
              "Posted successfully",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );

        // Refresh the feed after posting
        await fetchClubFeeds();

        print("Post successful: ${response.statusCode}");
      } else {
        print("Feed post error: $responseData");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to post: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Feed post exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // UPDATED: Support multiple images in update
  Future<void> _updateFeedPost(
    int postId,
    String title,
    String description,
    List<XFile?>? imageFiles,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login to update")));
        return;
      }

      print("Updating feed post ID: $postId with ${imageFiles?.length ?? 0} images");

      final url = Uri.parse("$api/api/myskates/club/feed/$postId/");

      final request = http.MultipartRequest("PUT", url);

      request.headers["Authorization"] = "Bearer $token";
      request.headers["Accept"] = "application/json";

      if (title.isNotEmpty) {
        request.fields["title"] = title;
      }

      if (description.isNotEmpty) {
        request.fields["description"] = description;
      }

      request.fields["club"] = widget.clubid.toString();

      //Add multiple images
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (var imageFile in imageFiles) {
          if (imageFile != null) {
            final file = File(imageFile.path);
            if (await file.exists()) {
              print("File exists: ${file.lengthSync()} bytes");
              request.files.add(
                await http.MultipartFile.fromPath("images", imageFile.path),
              );
            } else {
              print("File does not exist: ${imageFile.path}");
            }
          }
        }
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print("Feed update response status: ${response.statusCode}");
      print("Feed update response body: $responseData");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text(
              "Post updated successfully",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );

        await fetchClubFeeds();

        print("Update successful: ${response.statusCode}");
      } else {
        print("Feed update error: $responseData");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Feed update exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteFeedPost(int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login to delete")));
        return;
      }

      // Show confirmation dialog
      bool? confirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF06201A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              "Delete Post?",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Are you sure you want to delete this post?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      print("Deleting feed post with ID: $postId");

      final url = Uri.parse("$api/api/myskates/club/feed/$postId/");

      final response = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("Delete response status: ${response.statusCode}");
      print("Delete response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text(
              "Post deleted successfully",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );

        // Refresh the feed after deletion
        await fetchClubFeeds();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete post: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Delete feed post error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleLike(int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to like posts")),
        );
        return;
      }

      bool currentLiked = _likedPosts[postId] ?? false;
      int currentCount = _likeCounts[postId] ?? 0;

      setState(() {
        _likedPosts[postId] = !currentLiked;
        _likeCounts[postId] = currentLiked
            ? currentCount - 1
            : currentCount + 1;
      });

      final url = Uri.parse("$api/api/myskates/club/feed/$postId/like/");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("Like toggle response: ${response.statusCode}");
      print("Like toggle body: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        setState(() {
          _likedPosts[postId] = currentLiked;
          _likeCounts[postId] = currentCount;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to like post: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Like toggle error: $e");

      bool currentLiked = _likedPosts[postId] ?? false;
      int currentCount = _likeCounts[postId] ?? 0;

      setState(() {
        _likedPosts[postId] = currentLiked;
        _likeCounts[postId] = currentCount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleRepost(int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) return;

      final bool current = _repostedPosts[postId] ?? false;
      final int count = _repostCounts[postId] ?? 0;

      setState(() {
        _repostedPosts[postId] = !current;
        _repostCounts[postId] = current ? (count - 1) : (count + 1);
      });

      final url = Uri.parse("$api/api/myskates/club/feed/$postId/repost/");

      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      debugPrint("Repost => ${res.statusCode} ${res.body}");

      if (res.statusCode != 200 && res.statusCode != 201) {
        setState(() {
          _repostedPosts[postId] = current;
          _repostCounts[postId] = count;
        });
      }
    } catch (e) {
      debugPrint("Repost error: $e");
    }
  }

  Future<void> _fetchComments(int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) return;

      final url = Uri.parse(
        "$api/api/myskates/club/feed/$postId/comments/view/",
      );

      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final List commentsList = (data is Map && data["data"] is List)
            ? data["data"]
            : (data is List ? data : []);

        setState(() {
          _postComments[postId] = commentsList.cast<dynamic>();
          _commentCounts[postId] = commentsList.length;
        });
      } else {
        debugPrint("Fetch comments failed: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      debugPrint("Fetch comments error: $e");
    }
  }

  Future<void> _addComment(int postId, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null) return;

      final url = Uri.parse("$api/api/myskates/club/feed/$postId/comment/");
      final body = {
        "comment": text,
        if (userId != null) "user": userId,
        "feed": postId,
      };

      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      debugPrint("Add comment => ${res.statusCode} ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _fetchComments(postId);

        setState(() {
          _commentCounts[postId] = (_commentCounts[postId] ?? 0);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to comment: ${res.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Add comment error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateComment(int commentId, int postId, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) return;

      final url = Uri.parse(
        "$api/api/myskates/club/feed/comment/$commentId/update/delete/",
      );

      final request = http.Request("PATCH", url);
      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      });
      request.body = jsonEncode({"comment": text});

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      debugPrint("Update comment => ${res.statusCode} ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _fetchComments(postId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Comment updated successfully"),
              backgroundColor: Colors.teal,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update comment: ${res.body}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Update comment error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId, int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) return;

      final url = Uri.parse(
        "$api/api/myskates/club/feed/comment/$commentId/update/delete/",
      );

      final res = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      debugPrint("Delete comment => ${res.statusCode} ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 204) {
        await _fetchComments(postId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Comment deleted successfully"),
              backgroundColor: Colors.teal,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to delete comment: ${res.body}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Delete comment error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> fetchClubDetails() async {
    String? token = await getToken();
    if (token == null) {
      setState(() {
        loading = false;
        club = {};
      });
      return;
    }

    final response = await http.get(
      Uri.parse("$api/api/myskates/club/${widget.clubid}/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      setState(() {
        club = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
        club = {};
      });
    }
  }

  Future<void> submitEvent(
    String title,
    String note,
    String description,
    String fromDate,
    String toDate,
    String fromTime,
    String toTime,
    XFile? imageFile,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null || userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in")));
        return;
      }

      final url = Uri.parse("$api/api/myskates/events/add/");

      final request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";

      request.fields.addAll({
        "user": userId.toString(),
        "club": widget.clubid.toString(),
        "title": title,
        "note": note,
        "description": description,
        "from_date": fromDate,
        "to_date": toDate,
        "from_time": fromTime,
        "to_time": toTime,
      });

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", imageFile.path),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      print("EVENT RESPONSE: $respStr");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal,
            content: const Text(
              "Event added successfully",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add event: $respStr")),
        );
      }
    } catch (e) {
      print("Event Submit Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  List<dynamic> clubEvents = [];
  bool isEventsLoading = true;

  Future<void> fetchClubEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null || userId == null) return;

      final url = Uri.parse(
        "$api/api/myskates/events/view/$userId/${widget.clubid}/",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      print("Event fetch response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          clubEvents = jsonDecode(response.body);
          isEventsLoading = false;
        });
      } else {
        setState(() {
          clubEvents = [];
          isEventsLoading = false;
        });
      }
    } catch (e) {
      print("Event fetch error: $e");
      setState(() {
        clubEvents = [];
        isEventsLoading = false;
      });
    }
  }

  List<String> getMediaImagesFromEvents() {
    final List<String> media = [];

    for (var event in clubEvents) {
      if (event["image"] != null && event["image"].toString().isNotEmpty) {
        media.add(
          event["image"].toString().startsWith("http")
              ? event["image"]
              : "$api${event["image"]}",
        );
      }

      if (event["images"] is List) {
        for (var img in event["images"]) {
          if (img["image"] != null && img["image"].toString().isNotEmpty) {
            media.add(
              img["image"].toString().startsWith("http")
                  ? img["image"]
                  : "$api${img["image"]}",
            );
          }
        }
      }
    }

    return media;
  }

  Future<void> _deleteEvent(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final url = Uri.parse("$api/api/myskates/events/delete/$eventId/");

      final response = await http.delete(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal,
            content: const Text(
              "Event deleted",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );

        fetchClubEvents();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to delete event")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  String formatDate(String date) {
    try {
      final parts = date.split("-");
      if (parts.length == 3) {
        final yyyy = parts[0];
        final mm = parts[1];
        final dd = parts[2];
        return "$dd/$mm/$yyyy";
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  Future<void> _uploadMedia(XFile file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null || userId == null) return;

      final url = Uri.parse("$api/api/myskates/club-media/add/");

      final request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";

      request.fields.addAll({
        "club": widget.clubid.toString(),
        "user": userId.toString(),
      });

      request.files.add(await http.MultipartFile.fromPath("image", file.path));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text(
              "Media added successfully",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $respStr")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _openCommentsSheet(int postId) async {
    await _fetchComments(postId);

    final TextEditingController ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            final comments = _postComments[postId] ?? [];

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00332D), Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Comments",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        // inside itemBuilder
                        final c = comments[i];

                        // ✅ Name
                        final firstName = (c["first_name"] ?? "")
                            .toString()
                            .trim();
                        final lastName = (c["last_name"] ?? "")
                            .toString()
                            .trim();

                        final name =
                            (("$firstName $lastName").trim().isNotEmpty)
                            ? ("$firstName $lastName").trim()
                            : (c["user_name"] ?? c["username"] ?? "User")
                                  .toString();

                        final text = (c["comment"] ?? c["text"] ?? "")
                            .toString();

                        final int commentId = c["id"] ?? 0;
                        final int commentUserId = c["user"] is int
                            ? c["user"]
                            : int.tryParse(c["user"]?.toString() ?? "") ?? 0;

                        final bool canManageComment =
                            _currentUserId != null &&
                            _currentUserId == commentUserId;

                        String? profile =
                            (c["profile_image"] ??
                                    c["user_profile"] ??
                                    c["profile"])
                                ?.toString();
                        if (profile != null) profile = profile.trim();

                        if (profile != null &&
                            profile.isNotEmpty &&
                            profile != "null") {
                          if (!profile.startsWith("http")) {
                            profile = Uri.parse(
                              api,
                            ).resolve(profile).toString();
                          }
                        } else {
                          profile = null;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white24,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white10,
                                backgroundImage: profile != null
                                    ? NetworkImage(profile)
                                    : null,
                                child: profile == null
                                    ? Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : "U",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (canManageComment)
                                          SizedBox(
                                            height: 26,
                                            width: 26,
                                            child: PopupMenuButton<String>(
                                              padding: EdgeInsets.zero,
                                              color: const Color(0xFF06201A),
                                              icon: const Icon(
                                                Icons.more_vert,
                                                color: Colors.white70,
                                                size: 18,
                                              ),
                                              onSelected: (value) async {
                                                if (value == "edit") {
                                                  _showEditCommentDialog(
                                                    commentId,
                                                    postId,
                                                    text,
                                                  );
                                                } else if (value == "delete") {
                                                  await _deleteComment(
                                                    commentId,
                                                    postId,
                                                  );
                                                }
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: "edit",
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.edit,
                                                        color: Colors.teal,
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        "Edit",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: "delete",
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        "Delete",
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      text,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 14,
                      right: 14,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                      top: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color(0xFF00AFA5),
                            decoration: InputDecoration(
                              hintText: "Write a comment...",
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            final text = ctrl.text.trim();
                            if (text.isEmpty) return;

                            ctrl.clear();
                            await _addComment(postId, text);

                            if (mounted) setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00AFA5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditCommentDialog(int commentId, int postId, String oldText) {
    final TextEditingController editController = TextEditingController(
      text: oldText,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF06201A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Edit Comment",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: editController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Update your comment",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00AFA5)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AFA5),
              ),
              onPressed: () async {
                final updatedText = editController.text.trim();
                if (updatedText.isEmpty) return;

                Navigator.pop(context);
                await _updateComment(commentId, postId, updatedText);
              },
              child: const Text(
                "Update",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openAddMediaSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00332D), Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Add Media",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF00AFA5),
                  size: 28,
                ),
                title: const Text(
                  "Choose from Gallery",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  Navigator.pop(context);

                  if (image != null) {
                    _uploadMedia(image);
                  }
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF00AFA5),
                  size: 28,
                ),
                title: const Text(
                  "Take a Photo",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                  );

                  Navigator.pop(context);

                  if (image != null) {
                    _uploadMedia(image);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String formatTime(String time24) {
    try {
      final parts = time24.split(":");
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      String period = hour >= 12 ? "PM" : "AM";

      hour = hour % 12;
      if (hour == 0) hour = 12;

      return "${hour.toString()}:${minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      return time24;
    }
  }

  String safeString(dynamic v) {
    if (v == null) return "";
    return v.toString();
  }

  String safeDate(dynamic v) {
    if (v == null || v.toString().isEmpty) return "-";
    return formatDate(v.toString());
  }

  String safeTime(dynamic v) {
    if (v == null || v.toString().isEmpty) return "-";
    return formatTime(v.toString());
  }

  Widget _eventTile(Map event) {
    List<String> images = [];

    final mainImage = safeString(event["image"]);
    if (mainImage.isNotEmpty) {
      images.add(mainImage);
    }

    if (event["images"] is List) {
      for (var g in event["images"]) {
        final img = safeString(g["image"]);
        if (img.isNotEmpty) images.add(img);
      }
    }

    images = images.map((path) {
      return path.startsWith("http")
          ? path
          : "$api${path.startsWith("/") ? path : "/$path"}";
    }).toList();

    PageController controller = PageController();
    int currentPage = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// INSTAGRAM STYLE IMAGE SLIDER
              if (images.isNotEmpty)
                Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: PageView.builder(
                        controller: controller,
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _openSquareMediaViewer(images[index]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                images[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// DOT INDICATOR
                    if (images.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: currentPage == index ? 10 : 6,
                            height: currentPage == index ? 10 : 6,
                            decoration: BoxDecoration(
                              color: currentPage == index
                                  ? const Color(0xFF00AFA5)
                                  : Colors.white38,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                  ],
                ),

              const SizedBox(height: 12),

              /// EVENT TITLE
              Text(
                safeString(event["title"]),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              /// DESCRIPTION
              Text(
                safeString(event["description"]),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 10),

              /// DATE
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Color(0xFF00AFA5),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "${safeDate(event["from_date"])} → ${safeDate(event["to_date"])}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              /// TIME
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Color(0xFF00AFA5),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "${safeTime(event["from_time"])} → ${safeTime(event["to_time"])}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fancySwipeEventTile(Map event) {
    return Dismissible(
      key: Key(event["id"].toString()),
      direction: DismissDirection.horizontal,
      background: Container(
        padding: const EdgeInsets.only(left: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00AFA5), Colors.black],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.edit, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text("Update", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),

      secondaryBackground: Container(
        padding: const EdgeInsets.only(right: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red, Colors.black],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text("Delete", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),

      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          print("Update clicked");
          return false;
        } else {
          bool? confirm = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF06201A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: const Text(
                  "Delete Event?",
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  "Are you sure you want to delete this event?",
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white70),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              );
            },
          );

          if (confirm == true) {
            _deleteEvent(event["id"]);
            return true;
          } else {
            return false;
          }
        }
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: Transform.scale(scale: 1.00, child: _eventTile(event)),
      ),
    );
  }

  Widget _dateField(
    String label,
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                suffixIcon: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF00AFA5),
                ),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _openProfileImageViewer(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CircleAvatar(
                  radius: 100,
                  backgroundImage: NetworkImage(imageUrl),
                ),
              ),

              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleReview(RatingData rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[800],
                backgroundImage:
                    rating.userImage != null && rating.userImage!.isNotEmpty
                    ? NetworkImage(rating.userImage!)
                    : null,
                child: rating.userImage == null || rating.userImage!.isEmpty
                    ? Text(
                        rating.userName.isNotEmpty
                            ? rating.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            rating.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00AFA5).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFF00AFA5),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.rating.toString(),
                                style: const TextStyle(
                                  color: Color(0xFF00AFA5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    if (rating.review.isNotEmpty)
                      Text(
                        rating.review,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      const Text(
                        "No review provided",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                    const SizedBox(height: 6),

                    Text(
                      _formatDate(rating.createdAt),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.teal;
      case 'rejected':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return "${(difference.inDays / 365).floor()}y ago";
      } else if (difference.inDays > 30) {
        return "${(difference.inDays / 30).floor()}mo ago";
      } else if (difference.inDays > 0) {
        return "${difference.inDays}d ago";
      } else if (difference.inHours > 0) {
        return "${difference.inHours}h ago";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes}m ago";
      } else {
        return "Just now";
      }
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildPendingSummary() {
    if (!_isCoach) return const SizedBox();

    final pendingCount = _recentRatings
        .where((r) => r.approvalStatus == 'pending')
        .length;

    if (pendingCount == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                "$pendingCount Pending Review${pendingCount > 1 ? 's' : ''}",
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClubRatingApprovalPage(
                    clubId: widget.clubid,
                    clubName: club?["club_name"] ?? "Club",
                  ),
                ),
              );
            },
            child: const Text(
              "Manage",
              style: TextStyle(color: Color(0xFF00AFA5)),
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Support multiple images in update dialog
  void _showUpdatePostDialog(Map<String, dynamic> post) {
    final TextEditingController titleController = TextEditingController(
      text: post['title'] ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: post['description'] ?? '',
    );
    List<XFile?> selectedImages = [];
    List<String> existingImageUrls = [];

    // Get existing image URLs
    if (post['images'] != null && post['images'] is List) {
      var imagesList = post['images'] as List;
      for (var img in imagesList) {
        if (img is Map && img['image'] != null) {
          String imageUrl = img['image'].toString();
          if (!imageUrl.startsWith('http')) {
            imageUrl = imageUrl.startsWith('/')
                ? "$api$imageUrl"
                : "$api/$imageUrl";
          }
          existingImageUrls.add(imageUrl);
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00332D), Colors.black],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Update Post",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title field
                      TextField(
                        controller: titleController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          hintText: "Title",
                          hintStyle: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white10,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF00AFA5),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Description field
                      TextField(
                        controller: descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          hintText: "What's on your mind?",
                          hintStyle: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white10,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF00AFA5),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Existing images
                      if (existingImageUrls.isNotEmpty && selectedImages.isEmpty) ...[
                        const Text(
                          "Current Images:",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: existingImageUrls.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: NetworkImage(existingImageUrls[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setStateSB(() {
                                          existingImageUrls.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],

                      // New selected images
                      if (selectedImages.isNotEmpty) ...[
                        const Text(
                          "New Images:",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: FileImage(File(selectedImages[index]!.path)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setStateSB(() {
                                          selectedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],

                      // Image picker button
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final List<XFile> images = await picker.pickMultiImage();
                          if (images.isNotEmpty) {
                            setStateSB(() {
                              selectedImages.addAll(images);
                              existingImageUrls.clear();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00AFA5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFF00AFA5).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.image,
                                color: Color(0xFF00AFA5),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedImages.isNotEmpty || existingImageUrls.isNotEmpty
                                    ? "Add More Images"
                                    : "Choose Images",
                                style: const TextStyle(
                                  color: Color(0xFF00AFA5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00AFA5),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final title = titleController.text.trim();
                                final description = descriptionController.text
                                    .trim();

                                if (title.isEmpty && description.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please enter a title or description",
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pop(context);

                                // Show loading indicator
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.teal,
                                      ),
                                    );
                                  },
                                );

                                // If there are new images selected, use them; otherwise keep existing
                                List<XFile?>? imagesToUpdate = selectedImages.isNotEmpty 
                                    ? selectedImages 
                                    : null;

                                await _updateFeedPost(
                                  post['id'],
                                  title,
                                  description,
                                  imagesToUpdate,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text(
                                "Update",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // UPDATED: Display multiple images in feed post
  Widget _buildFeedPost(Map<String, dynamic> post) {
    debugPrint("BUILDING FEED POST: $post");

    final int postId = post['id'] ?? 0;
    final int postUserId = post['user'] ?? 0;

    final bool canDelete = _isCoach || (_currentUserId == postUserId);
    final bool canUpdate = _currentUserId == postUserId;

    // Username
    String userName = (post['user_name'] ?? 'User ${post['user'] ?? ''}')
        .toString();

    // Profile image
    String? userProfile = post['user_profile']?.toString();
    if (userProfile != null) userProfile = userProfile.trim();

    if (userProfile != null &&
        userProfile.isNotEmpty &&
        userProfile != "null") {
      if (!userProfile.startsWith('http')) {
        userProfile = userProfile.startsWith('/')
            ? "$api$userProfile"
            : "$api/$userProfile";
      }
    } else {
      userProfile = null;
    }

    final String title = (post['title'] ?? '').toString();
    final String description = (post['description'] ?? '').toString();
    final String createdAt = (post['created_at'] ?? '').toString();

    // Get all images
    List<String> imageUrls = [];
    if (post['images'] != null && post['images'] is List) {
      final imagesList = post['images'] as List;
      for (var img in imagesList) {
        if (img is Map && img['image'] != null) {
          String imageUrl = img['image'].toString().trim();
          if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
            imageUrl = imageUrl.startsWith('/')
                ? "$api$imageUrl"
                : "$api/$imageUrl";
          }
          imageUrls.add(imageUrl);
        }
      }
    }

    // Like state
    final bool isLiked = _likedPosts[postId] ?? false;
    final int likeCount = _likeCounts[postId] ?? (post['total_likes'] ?? 0);

    // Comment count
    final int commentCount =
        _commentCounts[postId] ?? (post['total_comments'] ?? 0);

    // Repost state + count
    final bool isReposted = _repostedPosts[postId] ?? false;
    final int repostCount =
        _repostCounts[postId] ?? (post['total_reposts'] ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User row + menu
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[800],
                backgroundImage: userProfile != null
                    ? NetworkImage(userProfile)
                    : null,
                child: userProfile == null
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _formatDate(createdAt),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (canUpdate || canDelete)
                PopupMenuButton<String>(
                  color: const Color(0xFF06201A),
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == "update" && canUpdate) {
                      _showUpdatePostDialog(post);
                    } else if (value == "delete" && canDelete) {
                      _deleteFeedPost(postId);
                    }
                  },
                  itemBuilder: (context) {
                    final List<PopupMenuEntry<String>> items = [];

                    if (canUpdate) {
                      items.add(
                        const PopupMenuItem(
                          value: "update",
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.teal, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Update",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (canDelete) {
                      items.add(
                        const PopupMenuItem(
                          value: "delete",
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return items;
                  },
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

          const SizedBox(height: 8),

          // Description
          if (description.isNotEmpty)
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),

          const SizedBox(height: 12),

          // Multiple Images with Slider
          if (imageUrls.isNotEmpty) ...[
            _buildImageSlider(imageUrls),
            const SizedBox(height: 12),
          ],

          // Like / Comment / Repost row
          Row(
            children: [
              // Like
              GestureDetector(
                onTap: () => _toggleLike(postId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isLiked
                        ? const Color(0xFF00AFA5).withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLiked
                          ? const Color(0xFF00AFA5).withOpacity(0.5)
                          : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked
                            ? const Color(0xFF00AFA5)
                            : Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        likeCount.toString(),
                        style: TextStyle(
                          color: isLiked
                              ? const Color(0xFF00AFA5)
                              : Colors.white70,
                          fontSize: 13,
                          fontWeight: isLiked
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLiked ? "Liked" : "Like",
                        style: TextStyle(
                          color: isLiked
                              ? const Color(0xFF00AFA5)
                              : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Comment
              GestureDetector(
                onTap: () => _openCommentsSheet(postId),
                child: Row(
                  children: [
                    const Icon(
                      Icons.comment_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      commentCount.toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Repost
              GestureDetector(
                onTap: () => _toggleRepost(postId),
                child: Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      color: isReposted
                          ? const Color(0xFF00AFA5)
                          : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      repostCount.toString(),
                      style: TextStyle(
                        color: isReposted
                            ? const Color(0xFF00AFA5)
                            : Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  // ADD THIS NEW METHOD: Image slider for multiple images
  Widget _buildImageSlider(List<String> imageUrls) {
    final PageController controller = PageController();
    int currentPage = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: controller,
                itemCount: imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openSquareMediaViewer(imageUrls[index]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrls[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 250,
                            color: Colors.grey[900],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.teal,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: Colors.grey[900],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.white54),
                                  SizedBox(height: 8),
                                  Text(
                                    "Failed to load image",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            if (imageUrls.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imageUrls.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentPage == index ? 8 : 6,
                    height: currentPage == index ? 8 : 6,
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? const Color(0xFF00AFA5)
                          : Colors.white38,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    final Map<String, dynamic> c = club ?? {};

    final String clubName = (c["club_name"] ?? "").toString();
    final String place = (c["place"] ?? "").toString();
    final String districtName = (c["district_name"] ?? "").toString();
    final String stateName = (c["state_name"] ?? "").toString();
    final String description = (c["description"] ?? "").toString();
    final String instagram = (c["instagram"] ?? "").toString();
    final String website = (c["website"] ?? "").toString();
    final String? imagePath = c["image"]?.toString();
    final mediaImages = getMediaImagesFromEvents();

    return Scaffold(
      backgroundColor: Colors.black,

      body: RefreshIndicator(
        onRefresh: _refreshClubView,
        color: const Color(0xFF00AFA5),
        backgroundColor: Colors.black87,
        strokeWidth: 3.0,
        displacement: 40.0,
        edgeOffset: 20.0,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00332D), Colors.black],
            ),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (imagePath != null && imagePath!.isNotEmpty) {
                          _openProfileImageViewer("$api$imagePath");
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            (imagePath != null && imagePath!.isNotEmpty)
                            ? NetworkImage("$api$imagePath")
                            : const AssetImage("lib/assets/placeholder.png")
                                  as ImageProvider,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clubName,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            [
                              if (place.isNotEmpty) place,
                              if (districtName.isNotEmpty) districtName,
                              if (stateName.isNotEmpty) stateName,
                            ].join(", "),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "$followersCount Members joined",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),

                          if (!_isClubLoading && !_isMyClub) ...[
                            const SizedBox(height: 12),
                            _buildClubActionButton(),
                          ],

                          if (_hasUserRated && widget.isApproved) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _showUpdateRatingDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00AFA5,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF00AFA5,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Color(0xFF00AFA5),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Your Rating: ${_userRating?.rating}",
                                      style: const TextStyle(
                                        color: Color(0xFF00AFA5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.edit,
                                      color: Color(0xFF00AFA5),
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: const Color(0xFF06201A),
                      onSelected: (value) {
                        if (value == "followers") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ClubFollowersPage(clubId: widget.clubid),
                            ),
                          );
                        } else if (value == "approvals" && _isCoach) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClubRatingApprovalPage(
                                clubId: widget.clubid,
                                clubName: clubName,
                              ),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) {
                        List<PopupMenuEntry<String>> items = [
                          const PopupMenuItem(
                            value: "followers",
                            child: Text(
                              "   View Followers",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ];

                        if (_isCoach) {
                          final pendingCount = _recentRatings
                              .where((r) => r.approvalStatus == 'pending')
                              .length;

                          items.add(
                            PopupMenuItem(
                              value: "approvals",
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Manage Approvals",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  if (pendingCount > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        pendingCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }

                        return items;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  "Overview",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 12),

                if (instagram.isNotEmpty)
                  Text(
                    instagram,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),

                if (website.isNotEmpty)
                  Text(
                    website,
                    style: const TextStyle(
                      color: Color(0xFF00AFA5),
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),

                const SizedBox(height: 35),

                if (_canViewFullClubPage) ...[
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 3,
                        minY: 2,
                        maxY: 4,
                        borderData: FlBorderData(show: true),
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 70,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 4:
                                    return const Text(
                                      "Excellent",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  case 3:
                                    return const Text(
                                      "High",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  case 2:
                                    return const Text(
                                      "Low",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  default:
                                    return const SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                const textStyle = TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                );

                                switch (value.toInt()) {
                                  case 0:
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text("Aug", style: textStyle),
                                    );
                                  case 1:
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text("Sept", style: textStyle),
                                    );
                                  case 2:
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text("Oct", style: textStyle),
                                    );
                                  case 3:
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text("Nov", style: textStyle),
                                    );
                                  default:
                                    return const SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: const Color(0xFF00E5D0),
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            spots: const [
                              FlSpot(0, 3),
                              FlSpot(1, 4),
                              FlSpot(2, 3),
                              FlSpot(3, 2),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  const Text(
                    "Feed",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // UPDATED: Feed input box with multi-image support
                  _feedInputBox(
                    onSubmit: (title, description, images) {
                      submitFeedPost(title, description, images);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Feed Posts Display
                  if (isFeedLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Colors.teal),
                      ),
                    )
                  else if (feedPosts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "No posts yet. Be the first to post!",
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: feedPosts.length,
                      itemBuilder: (context, index) {
                        return _buildFeedPost(feedPosts[index]);
                      },
                    ),
                  const SizedBox(height: 25),

                  const Text(
                    "Media",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ...mediaImages
                            .take(10)
                            .map((img) => _mediaItem(img))
                            .toList(),

                        Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              "View\nall",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  // REVIEWS SECTION
                  const Text(
                    "Reviews",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (_recentRatings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "No reviews yet",
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        _buildPendingSummary(),

                        const SizedBox(height: 16),

                        ..._recentRatings
                            .take(1)
                            .map((rating) => _buildSingleReview(rating))
                            .toList(),

                        if (_recentRatings.length > 1)
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClubReviewsViewPage(
                                      clubId: widget.clubid,
                                      clubName: clubName,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "View All Reviews",
                                style: TextStyle(
                                  color: Color(0xFF00AFA5),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                  const SizedBox(height: 35),

                  const Text(
                    "Events",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (isEventsLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.teal),
                    )
                  else if (clubEvents.isEmpty)
                    const Text(
                      "No events found.",
                      style: TextStyle(color: Colors.white70),
                    )
                  else
                    Column(
                      children: clubEvents.map((event) {
                        return _eventTile(event);
                      }).toList(),
                    ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: _isCoach
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "media_btn",
                  backgroundColor: const Color(0xFF00AFA5),
                  elevation: 5,
                  child: const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: Color.fromARGB(255, 252, 252, 252),
                    size: 30,
                  ),
                  onPressed: _openAddMediaSheet,
                ),
                const SizedBox(height: 12),

                FloatingActionButton(
                  heroTag: "event_btn",
                  backgroundColor: const Color(0xFF00AFA5),
                  child: const Icon(Icons.event, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CoachAddEvents(clubid: widget.clubid),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFF00AFA5),
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: ""),
        ],
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00AFA5),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00AFA5),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      controller.text =
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
  }

  Widget _timeField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.access_time, color: Color(0xFF00AFA5)),
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          readOnly: true,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _openAddEventDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachAddEvents(clubid: widget.clubid),
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _mediaItem(String url) {
    return GestureDetector(
      onTap: () => _openSquareMediaViewer(url),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
      ),
    );
  }

  void _openSquareMediaViewer(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _coachTile(String name, String img) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundImage: NetworkImage(img)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 17),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
        ],
      ),
    );
  }
}

// UPDATED: Feed input box with multi-image support
Widget _feedInputBox({required Function(String, String, List<XFile?>?) onSubmit}) {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<XFile?> selectedImages = [];

  return StatefulBuilder(
    builder: (context, setStateSB) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Title field
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                hintText: "Title",
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                filled: true,
                fillColor: Colors.white10,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              minLines: 2,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                hintText: "What's on your mind?",
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                filled: true,
                fillColor: Colors.white10,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Display selected images
            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: FileImage(File(selectedImages[index]!.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setStateSB(() {
                                selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Image picker button - now supports multiple images
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final List<XFile> images = await picker.pickMultiImage();
                    if (images.isNotEmpty) {
                      setStateSB(() {
                        selectedImages.addAll(images);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00AFA5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: Color(0xFF00AFA5),
                      size: 26,
                    ),
                  ),
                ),

                // Post button
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AFA5),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      final title = titleController.text.trim();
                      final description = descriptionController.text.trim();

                      if (title.isEmpty && description.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please enter a title or description",
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      onSubmit(title, description, selectedImages.isEmpty ? null : selectedImages);

                      titleController.clear();
                      descriptionController.clear();
                      setStateSB(() {
                        selectedImages.clear();
                      });
                    },
                    child: const Text(
                      "Post",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

Widget _feedTile(Map post) {
  final String? image = post["image"];
  final String text = post["text"] ?? "";
  final String time = post["created_at"] ?? "";

  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),

        const SizedBox(height: 10),

        if (image != null && image.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              "$api$image",
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),

        const SizedBox(height: 10),

        Text(time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    ),
  );
}

class SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: borderRadius,
      ),
    );
  }
}

class RatingPopup extends StatefulWidget {
  final int clubId;
  final Function(int, String) onSubmit;
  final VoidCallback onSkip;
  final int? initialRating;
  final String? initialReview;
  final bool isUpdate;

  const RatingPopup({
    Key? key,
    required this.clubId,
    required this.onSubmit,
    required this.onSkip,
    this.initialRating,
    this.initialReview,
    this.isUpdate = false,
  }) : super(key: key);

  @override
  State<RatingPopup> createState() => _RatingPopupState();
}

class _RatingPopupState extends State<RatingPopup> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRating != null) {
      _rating = widget.initialRating!;
    }
    if (widget.initialReview != null) {
      _reviewController.text = widget.initialReview!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00332D), Colors.black],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isUpdate ? "Update Rating" : "Rate this Club",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: widget.onSkip,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFF00AFA5),
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 10),

              Text(
                _rating == 0 ? "Tap to rate" : _getRatingText(_rating),
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _reviewController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Write your review (optional)...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00AFA5)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : widget.onSkip,
                      child: Text(
                        widget.isUpdate ? "Cancel" : "Skip",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AFA5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSubmitting || _rating == 0
                          ? null
                          : () async {
                              setState(() {
                                _isSubmitting = true;
                              });
                              await widget.onSubmit(
                                _rating,
                                _reviewController.text.trim(),
                              );
                              setState(() {
                                _isSubmitting = false;
                              });
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.isUpdate ? "Update" : "Submit",
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return "Poor";
      case 2:
        return "Fair";
      case 3:
        return "Good";
      case 4:
        return "Very Good";
      case 5:
        return "Excellent";
      default:
        return "";
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}

class ClubReviewsViewPage extends StatelessWidget {
  final int clubId;
  final String clubName;

  const ClubReviewsViewPage({
    Key? key,
    required this.clubId,
    required this.clubName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Reviews - $clubName",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00332D), Colors.black],
          ),
        ),
        child: FutureBuilder<List<RatingData>>(
          future: _fetchAllApprovedRatings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.reviews, size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      "No reviews yet",
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final reviews = snapshot.data!;

            double avg = 0;
            for (var r in reviews) {
              avg += r.rating;
            }
            avg = avg / reviews.length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00AFA5).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          avg.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF00AFA5),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Average Rating",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < avg.floor()
                                      ? Icons.star
                                      : i < avg
                                      ? Icons.star_half
                                      : Icons.star_border,
                                  color: const Color(0xFF00AFA5),
                                  size: 20,
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'}",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                ...reviews.map((review) => _buildReviewCard(review)).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<RatingData>> _fetchAllApprovedRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) return [];

      final response = await http.get(
        Uri.parse("$api/api/myskates/club/rating/$clubId/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("Ratings API Response: ${response.statusCode}");
      print("Ratings API Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> ratings = jsonDecode(response.body);

        final approvedRatings = ratings
            .where((r) => r['approval_status'] == 'approved')
            .toList();

        List<RatingData> ratingDataList = [];

        for (var rating in approvedRatings) {
          String firstName = rating['user_first_name'] ?? '';
          String lastName = rating['user_last_name'] ?? '';
          String userName = '';

          if (firstName.isNotEmpty && lastName.isNotEmpty) {
            userName = '$firstName $lastName';
          } else if (firstName.isNotEmpty) {
            userName = firstName;
          } else if (lastName.isNotEmpty) {
            userName = lastName;
          } else {
            userName = 'User ${rating['user']}';
          }

          String? userImage = rating['profile'];
          if (userImage != null && userImage.isNotEmpty) {
            if (!userImage.startsWith('http')) {
              userImage = userImage.startsWith('/')
                  ? "$api$userImage"
                  : "$api/$userImage";
            }
          }

          ratingDataList.add(
            RatingData(
              id: rating['id'],
              rating: rating['rating'],
              review: rating['review'] ?? '',
              userName: userName,
              userImage: userImage,
              createdAt: rating['created_at'] ?? '',
              approvalStatus: rating['approval_status'] ?? 'pending',
            ),
          );
        }

        return ratingDataList;
      }
    } catch (e) {
      print("Error fetching all ratings: $e");
    }
    return [];
  }

  Widget _buildReviewCard(RatingData rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[800],
                backgroundImage:
                    rating.userImage != null && rating.userImage!.isNotEmpty
                    ? NetworkImage(rating.userImage!)
                    : null,
                child: rating.userImage == null || rating.userImage!.isEmpty
                    ? Text(
                        rating.userName.isNotEmpty
                            ? rating.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating.rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFF00AFA5),
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rating.review.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rating.review,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _formatDate(rating.createdAt),
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return "${(difference.inDays / 365).floor()}y ago";
      } else if (difference.inDays > 30) {
        return "${(difference.inDays / 30).floor()}mo ago";
      } else if (difference.inDays > 0) {
        return "${difference.inDays}d ago";
      } else if (difference.inHours > 0) {
        return "${difference.inHours}h ago";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes}m ago";
      } else {
        return "Just now";
      }
    } catch (e) {
      return dateString;
    }
  }
}

Widget _eventImageSlider(List images) {
  final PageController controller = PageController();
  int currentPage = 0;

  return StatefulBuilder(
    builder: (context, setState) {
      return Column(
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: controller,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "$api${images[index]["image"]}",
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: currentPage == index ? 10 : 6,
                height: currentPage == index ? 10 : 6,
                decoration: BoxDecoration(
                  color: currentPage == index
                      ? const Color(0xFF00AFA5)
                      : Colors.white30,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      );
    },
  );
}