import 'package:bladi_go_client/pages/notificationpage/proposa.dart';
import 'package:bladi_go_client/provider/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bladi_go_client/pages/notificationpage/detailbg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  late AnimationController _refreshAnimationController;
  late TabController _tabController;
  bool hasRefreshed = false;

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchNotifications();
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    switch (_tabController.index) {
      case 0: // All
        return notifications;
      case 1: // Pending
        return notifications.where((n) {
          final String status = n['rawStatus'] ?? '';
          return status == 'En attente' ||
              status == 'En proposition' ||
              status.startsWith('Contre-proposition Client');
        }).toList();
      case 2: // Completed
        return notifications.where((n) {
          final String status = n['rawStatus'] ?? '';
          return status == 'Accepté' || status == 'Payé' || status == 'Refusé';
        }).toList();
      default:
        return notifications;
    }
  }

  Future<String> _fetchDriverName(String chauffeurId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('chauffeurs')
          .doc(chauffeurId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final name = data['name'] ?? 'Inconnu';
        final lastName = data['lastName'] ?? '';
        return '$name $lastName'.trim();
      }
      return 'Chauffeur non attribué';
    } catch (e) {
      debugPrint('Erreur lors de la récupération du chauffeur: $e');
      return 'Chauffeur non attribué';
    }
  }

  Future<Map<String, dynamic>> _fetchTrajetDetails(String trajetId) async {
    try {
      final trajetDoc = await FirebaseFirestore.instance
          .collection('trajets')
          .doc(trajetId)
          .get();
      if (trajetDoc.exists) {
        final data = trajetDoc.data()!;
        final value = data['value']?.split(' → ') ?? ['N/A', 'N/A'];
        return {
          'collectionPoint': value[0],
          'deliveryPoint': value[1],
          'date': data['date'] ?? 'N/A',
        };
      }
      return {
        'collectionPoint': 'N/A',
        'deliveryPoint': 'N/A',
        'date': 'N/A',
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération du trajet: $e');
      return {
        'collectionPoint': 'N/A',
        'deliveryPoint': 'N/A',
        'date': 'N/A',
      };
    }
  }

  Future<void> _fetchNotifications() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      isLoading = true;
    });

    _refreshAnimationController.forward().then((_) {
      _refreshAnimationController.reset();
    });

    try {
      debugPrint('Fetching notifications for userId: ${userProvider.userId}');

      final snapshot = await FirebaseFirestore.instance
          .collection('baggage')
          .where('userId', isEqualTo: userProvider.userId)
          .get();

      debugPrint('Found ${snapshot.docs.length} documents');

      final List<Map<String, dynamic>> newNotifications = [];
      final Map<String, Map<String, dynamic>> uniqueNotifications = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String docId = doc.id;
        final String? trajetId = data['trajetId'] as String?;
        final String chauffeurId = data['chauffeurId'] ?? '';

        if (trajetId == null) {
          debugPrint('Skipping doc ${doc.id} - missing trajetId');
          continue;
        }

        final trajetDetails = await _fetchTrajetDetails(trajetId);
        String driverName = 'En attente';

        if (chauffeurId.isNotEmpty) {
          driverName = await _fetchDriverName(chauffeurId);
        }

        final status = data['status'] ?? 'Statut inconnu';

        String statusMessage;
        Color statusColor;
        IconData statusIcon;

        switch (status) {
          case 'En attente':
            statusMessage = 'Vous avez une demande en attente';
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_empty;
            break;
          case 'En proposition':
            statusMessage = 'Votre demande est en proposition';
            statusColor = Colors.blue;
            statusIcon = Icons.assignment_outlined;
            break;
          case 'Contre-proposition Client 1':
            statusMessage = 'Contre-proposition 1 en attente';
            statusColor = Colors.orangeAccent;
            statusIcon = Icons.price_change_outlined;
            break;
          case 'Contre-proposition Client 2':
            statusMessage = 'Contre-proposition 2 en attente';
            statusColor = Colors.orangeAccent;
            statusIcon = Icons.price_change_outlined;
            break;
          case 'Contre-proposition Client 3':
            statusMessage = 'Contre-proposition 3 en attente';
            statusColor = Colors.orangeAccent;
            statusIcon = Icons.price_change_outlined;
            break;
          case 'Accepté':
            statusMessage = 'Vous avez accepté la proposition';
            statusColor = Colors.green;
            statusIcon = Icons.check_circle_outline;
            break;
          case 'Refusé':
            statusMessage = 'Vous avez refusé la demande';
            statusColor = Colors.red;
            statusIcon = Icons.cancel_outlined;
            break;
          case 'Payé':
            statusMessage = 'Votre paiement a été effectué avec succès';
            statusColor = Colors.blue;
            statusIcon = Icons.payments_outlined;
            break;
          default:
            statusMessage = status;
            statusColor = const Color.fromARGB(255, 165, 165, 165);
            statusIcon = Icons.info_outline;
        }

        uniqueNotifications[docId] = {
          'id': docId,
          'date': trajetDetails['date'],
          'collectionPoint': data['from'],
          'deliveryPoint': data['to'],
          'driverName': driverName,
          'status': statusMessage,
          'rawStatus': status,
          'statusColor': '#${statusColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
          'statusIcon': statusIcon,
          'chauffeurId': chauffeurId,
          'trajetId': trajetId,
          'userId': userProvider.userId,
          'items': data['items'] as List<dynamic>? ?? [],
          'timestamp': data['timestamp'] ?? Timestamp.now(),
        };
      }

      newNotifications.addAll(uniqueNotifications.values.toList());
      newNotifications.sort((a, b) {
        final Timestamp timestampA = a['timestamp'] as Timestamp;
        final Timestamp timestampB = b['timestamp'] as Timestamp;
        return timestampB.compareTo(timestampA);
      });

      setState(() {
        notifications = newNotifications;
        isLoading = false;
        hasRefreshed = true;
        debugPrint('State updated with ${notifications.length} notifications');
      });
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() {
        isLoading = false;
      });
      _showErrorSnackbar(e.toString());
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: $message'),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: _fetchNotifications,
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    return DateFormat('dd/MM/yy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: _refreshAnimationController, curve: Curves.elasticOut),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: _fetchNotifications,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: "Toutes"),
                Tab(text: "En cours"),
                Tab(text: "Complétées"),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingState()
          : notifications.isEmpty
              ? _buildEmptyState()
              : _filteredNotifications.isEmpty
                  ? _buildEmptyFilterState()
                  : _buildNotificationList(_filteredNotifications, context),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Chargement des notifications...',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
            child: Icon(Icons.notifications_off_outlined,
                size: 60, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune notification',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Vous serez notifié lorsque vous aurez des mises à jour concernant vos demandes',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 32),
          if (!hasRefreshed)
            ElevatedButton.icon(
              onPressed: _fetchNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Rafraîchir'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuint),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(Icons.filter_list, size: 50, color: Colors.blue.shade400),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun résultat trouvé',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Aucune notification ne correspond au filtre actuel',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              _tabController.animateTo(0);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Voir toutes les notifications'),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> notifications, BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          var notification = notifications[index];
          Color statusColor =
              Color(int.parse(notification['statusColor'].replaceAll('#', '0xFF')));
          IconData statusIcon = notification['statusIcon'] ?? Icons.local_shipping;

          return Animate(
            effects: [
              FadeEffect(duration: 400.ms, delay: (50 * index).ms),
              SlideEffect(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
                duration: 400.ms,
                curve: Curves.easeOutQuad,
                delay: (50 * index).ms,
              ),
            ],
            child: Card(
              elevation: 2,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: statusColor.withOpacity(0.2), width: 1),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, statusColor.withOpacity(0.05)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          border: Border(
                            bottom: BorderSide(
                              color: statusColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                notification['status'],
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor),
                              ),
                            ),
                            Text(
                              _formatTimestamp(notification['timestamp']),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    Container(
                                      width: 2,
                                      height: 30,
                                      color: Colors.grey.shade300,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade700,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Point de collecte',
                                            style: TextStyle(
                                                fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notification['collectionPoint'],
                                            style: const TextStyle(
                                                fontSize: 15, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Point de livraison',
                                            style: TextStyle(
                                                fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notification['deliveryPoint'],
                                            style: const TextStyle(
                                                fontSize: 15, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.shade200),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildInfoItem(
                                    Icons.calendar_today_outlined, 'Date', notification['date']),
                                const SizedBox(width: 24),
                                _buildInfoItem(Icons.person_outline_rounded, 'Chauffeur',
                                    notification['driverName']),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildActionButton(notification, context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> notification, BuildContext context) {
    final String rawStatus = notification['rawStatus'] ?? '';
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    String buttonText;
    Color buttonColor;
    IconData buttonIcon;
    VoidCallback? onPressed;

    switch (rawStatus) {
      case 'En attente':
        buttonText = 'Voir les détails';
        buttonColor = Colors.orange.shade600;
        buttonIcon = Icons.visibility;
        onPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModernBaggageScreen(
                userId: userProvider.userId,
                selectedDate: notification['date'],
                collectionPoint: notification['collectionPoint'],
                deliveryPoint: notification['deliveryPoint'],
              ),
            ),
          ).then((_) {
            _fetchNotifications();
          });
        };
        break;
      case 'En proposition':
        buttonText = 'Voir la proposition';
        buttonColor = Colors.blue;
        buttonIcon = Icons.description_outlined;
        onPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChauffeurProposalScreen(
                trajetId: notification['trajetId'],
                chauffeurId: notification['chauffeurId'],
                date: notification['date'],
                collectionPoint: notification['collectionPoint'],
                deliveryPoint: notification['deliveryPoint'],
              ),
            ),
          ).then((_) {
            _fetchNotifications();
          });
        };
        break;
      case 'Contre-proposition Client 1':
      case 'Contre-proposition Client 2':
      case 'Contre-proposition Client 3':
        buttonText = 'Voir la contre-proposition';
        buttonColor = Colors.orangeAccent;
        buttonIcon = Icons.price_change_outlined;
        onPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChauffeurProposalScreen(
                trajetId: notification['trajetId'],
                chauffeurId: notification['chauffeurId'],
                date: notification['date'],
                collectionPoint: notification['collectionPoint'],
                deliveryPoint: notification['deliveryPoint'],
              ),
            ),
          ).then((_) {
            _fetchNotifications();
          });
        };
        break;
      case 'Accepté':
        buttonText = 'Voir les détails';
        buttonColor = Colors.green;
        buttonIcon = Icons.check_circle_outline;
        onPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModernBaggageScreen(
                userId: userProvider.userId,
                selectedDate: notification['date'],
                collectionPoint: notification['collectionPoint'],
                deliveryPoint: notification['deliveryPoint'],
              ),
            ),
          ).then((_) {
            _fetchNotifications();
          });
        };
        break;
      case 'Refusé':
        buttonText = 'Voir les détails';
        buttonColor = Colors.red;
        buttonIcon = Icons.cancel_outlined;
        onPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModernBaggageScreen(
                userId: userProvider.userId,
                selectedDate: notification['date'],
                collectionPoint: notification['collectionPoint'],
                deliveryPoint: notification['deliveryPoint'],
              ),
            ),
          ).then((_) {
            _fetchNotifications();
          });
        };
        break;
      case 'Payé':
        buttonText = 'Position du chauffeur';
        buttonColor = Colors.blue;
        buttonIcon = Icons.location_on;
        onPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModernBaggageScreen(
                userId: userProvider.userId,
                selectedDate: notification['date'],
                collectionPoint: notification['collectionPoint'],
                deliveryPoint: notification['deliveryPoint'],
              ),
            ),
          ).then((_) {
            _fetchNotifications();
          });
        };
        break;
      default:
        return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(buttonIcon, size: 18),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }
}