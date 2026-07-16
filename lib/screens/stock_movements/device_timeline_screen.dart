import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cihaz_model.dart';
import '../../models/urun_model.dart';
import '../../models/stok_hareket_model.dart';
import '../../models/ariza_model.dart';
import '../../models/sevkiyat_model.dart';
import '../../models/montaj_model.dart';
import '../../models/islem_log_model.dart';
import '../../services/api_service.dart';
import '../../core/utils/date_utils.dart';
import '../shared/empty_state_widget.dart';
import '../shared/shimmer_loading.dart';

class TimelineEvent {
  final DateTime? date;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  TimelineEvent({
    this.date,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class DeviceTimelineScreen extends StatefulWidget {
  final CihazModel cihaz;
  final UrunModel urun;

  const DeviceTimelineScreen({
    super.key,
    required this.cihaz,
    required this.urun,
  });

  @override
  State<DeviceTimelineScreen> createState() => _DeviceTimelineScreenState();
}

class _DeviceTimelineScreenState extends State<DeviceTimelineScreen> {
  final _apiService = ApiService.instance;
  
  bool _isLoading = true;
  String? _error;
  List<TimelineEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cid = widget.cihaz.id;

      final results = await Future.wait([
        _apiService.stokHareketListele(cihazid: cid),
        _apiService.arizaListele(cihazid: cid),
        _apiService.sevkiyatListele(cihazid: cid),
        _apiService.montajListele(anacihazid: cid, gecmisdahil: true),
        _apiService.montajListele(bilesencihazid: cid, gecmisdahil: true),
        _apiService.islemLogListele(tablo: 'cihaz', kayitid: cid),
      ]);

      final stokHareketleri = results[0] as List<StokHareketModel>;
      final arizalar = results[1] as List<ArizaModel>;
      final sevkiyatlar = results[2] as List<SevkiyatModel>;
      final anacihazMontajlari = results[3] as List<MontajModel>;
      final bilesenMontajlari = results[4] as List<MontajModel>;
      final cihazLogs = results[5] as List<IslemLogModel>;

      // İşlem Loglarını Çekelim
      final List<Future<List<IslemLogModel>>> logFutures = [];
      for (var a in arizalar) {
        logFutures.add(_apiService.islemLogListele(tablo: 'ariza', kayitid: a.id));
      }
      for (var s in sevkiyatlar) {
        logFutures.add(_apiService.islemLogListele(tablo: 'sevkiyat', kayitid: s.id));
      }
      for (var m in anacihazMontajlari) {
        logFutures.add(_apiService.islemLogListele(tablo: 'montaj', kayitid: m.id));
      }
      for (var m in bilesenMontajlari) {
        logFutures.add(_apiService.islemLogListele(tablo: 'montaj', kayitid: m.id));
      }

      final logResults = await Future.wait(logFutures);
      
      final Map<int, List<IslemLogModel>> arizaLogs = {};
      final Map<int, List<IslemLogModel>> sevkiyatLogs = {};
      final Map<int, List<IslemLogModel>> montajLogs = {};
      
      int logIndex = 0;
      for (var a in arizalar) {
        arizaLogs[a.id] = logResults[logIndex++];
      }
      for (var s in sevkiyatlar) {
        sevkiyatLogs[s.id] = logResults[logIndex++];
      }
      for (var m in anacihazMontajlari) {
        montajLogs[m.id] = logResults[logIndex++];
      }
      for (var m in bilesenMontajlari) {
        montajLogs[m.id] = logResults[logIndex++];
      }

      final List<TimelineEvent> rawEvents = [];

      // 0. Cihaz Stoğa Eklendi
      final cihazEklemeLogs = cihazLogs.where((l) => l.islem == 'ekleme').toList();
      DateTime? cihazEklemeDt;
      if (cihazEklemeLogs.isNotEmpty && cihazEklemeLogs.first.kgt != null) {
        cihazEklemeDt = DateTime.tryParse(cihazEklemeLogs.first.kgt!);
      } else if (widget.cihaz.alimtarihi != null) {
        cihazEklemeDt = DateTime.tryParse(widget.cihaz.alimtarihi!);
      }

      if (cihazEklemeDt != null) {
        rawEvents.add(TimelineEvent(
          date: cihazEklemeDt,
          title: 'Cihaz Stoğa Kaydedildi',
          description: 'Cihaz sisteme ilk kez eklendi.',
          icon: Icons.add_business_rounded,
          color: Colors.green.shade800,
        ));
      }

      // 1. Stok Hareketleri
      for (var h in stokHareketleri) {
        DateTime? dt;
        if (h.kgt != null) dt = DateTime.tryParse(h.kgt!);
        
        String t = h.isGiris ? 'Stok Girişi' : 'Stok Çıkışı';
        IconData i = h.isGiris ? Icons.login_rounded : Icons.logout_rounded;
        Color c = h.isGiris ? AppTheme.successGreen : AppTheme.errorRed;

        if (h.aciklama != null && h.aciklama!.startsWith('Tamir/Bakım Notu:')) {
          t = 'Tamir / Bakım';
          i = Icons.home_repair_service_rounded;
          c = Colors.blueGrey;
        } else if (h.arizaid != null) {
          t = 'Arıza Kaydı Hareketi';
          i = Icons.build_circle_rounded;
          c = Colors.orange;
        }

        String desc = 'Durum: ${h.durumAdi}';
        if (h.aciklama != null && h.aciklama!.isNotEmpty) {
          desc += '\nNot: ${h.aciklama}';
        }

        rawEvents.add(TimelineEvent(
          date: dt,
          title: t,
          description: desc,
          icon: i,
          color: c,
        ));
      }

      // 2. Arızalar
      for (var a in arizalar) {
        DateTime? acilisDt;
        DateTime? kapanisDt;
        
        if (a.tamamlanmatarihi != null) {
          kapanisDt = DateTime.tryParse(a.tamamlanmatarihi!);
        }

        if (a.kgt != null) {
          acilisDt = DateTime.tryParse(a.kgt!);
        } else {
          // Stok hareketlerinden bulmaya çalış
          final ilgiliHareketler = stokHareketleri.where((h) => h.arizaid == a.id).toList();
          if (ilgiliHareketler.isNotEmpty) {
            ilgiliHareketler.sort((h1, h2) => (h1.kgt ?? '').compareTo(h2.kgt ?? ''));
            if (ilgiliHareketler.first.kgt != null) {
              acilisDt = DateTime.tryParse(ilgiliHareketler.first.kgt!);
            }
          }
        }
        
        final logs = arizaLogs[a.id] ?? [];
        
        // Eğer açılış tarihi hala null ise, işlem logundan 'ekleme' kaydını bul
        if (acilisDt == null) {
           final eklemeLog = logs.where((l) => l.islem == 'ekleme').toList();
           if (eklemeLog.isNotEmpty && eklemeLog.first.kgt != null) {
             acilisDt = DateTime.tryParse(eklemeLog.first.kgt!);
           }
        }
        
        // Eğer kapalıysa ama kapanış tarihi yoksa, işlem logundan 'guncelleme' (arizadurumu: 2) bul
        if (kapanisDt == null && !a.isAcik) {
           final kapanisLogs = logs.where((l) => l.islem == 'guncelleme' && l.detay != null && l.detay!['arizadurumu'] == 2).toList();
           if (kapanisLogs.isNotEmpty && kapanisLogs.first.kgt != null) {
             kapanisDt = DateTime.tryParse(kapanisLogs.first.kgt!);
           }
        }
        
        rawEvents.add(TimelineEvent(
          date: acilisDt,
          title: 'Arıza Kaydı Açıldı',
          description: a.aciklama ?? 'Açıklama yok',
          icon: Icons.report_problem_rounded,
          color: AppTheme.errorRed,
        ));

        // Eğer arıza kapalıysa, kapanış kaydını da ekle
        if (!a.isAcik) {
          rawEvents.add(TimelineEvent(
            date: kapanisDt,
            title: 'Arıza Kaydı Kapatıldı',
            description: a.aciklama ?? 'Açıklama yok',
            icon: Icons.check_circle_rounded,
            color: AppTheme.successGreen,
          ));
        }
      }

      // 3. Sevkiyatlar
      for (var s in sevkiyatlar) {
        final logs = sevkiyatLogs[s.id] ?? [];
        
        DateTime? hazirlandiDt;
        DateTime? gonderildiDt;
        DateTime? teslimDt;
        DateTime? iadeDt;
        
        final eklemeLogs = logs.where((l) => l.islem == 'ekleme').toList();
        if (eklemeLogs.isNotEmpty && eklemeLogs.first.kgt != null) {
          hazirlandiDt = DateTime.tryParse(eklemeLogs.first.kgt!);
        } else if (s.kdt != null) {
          hazirlandiDt = DateTime.tryParse(s.kdt!);
        } else if (s.kgt != null) {
          hazirlandiDt = DateTime.tryParse(s.kgt!); // Fallback
        }

        final gonderLogs = logs.where((l) => l.islem == 'guncelleme' && l.detay != null && (l.detay!['durum'].toString() == '2' || l.detay!['sevkiyatdurumu'].toString() == '2')).toList();
        if (gonderLogs.isNotEmpty && gonderLogs.first.kgt != null) {
          gonderildiDt = DateTime.tryParse(gonderLogs.first.kgt!);
        }

        final teslimLogs = logs.where((l) => l.islem == 'guncelleme' && l.detay != null && (l.detay!['durum'].toString() == '3' || l.detay!['sevkiyatdurumu'].toString() == '3')).toList();
        if (teslimLogs.isNotEmpty && teslimLogs.first.kgt != null) {
          teslimDt = DateTime.tryParse(teslimLogs.first.kgt!);
        }
        
        final iadeLogs = logs.where((l) => l.islem == 'guncelleme' && l.detay != null && (l.detay!['durum'].toString() == '4' || l.detay!['sevkiyatdurumu'].toString() == '4')).toList();
        if (iadeLogs.isNotEmpty && iadeLogs.first.kgt != null) {
          iadeDt = DateTime.tryParse(iadeLogs.first.kgt!);
        }
        
        String yonStr = s.yon == 1 ? "Giden" : "Gelen";
        String prefix = "$yonStr Sevkiyat";

        rawEvents.add(TimelineEvent(
          date: hazirlandiDt,
          title: '$prefix Oluşturuldu (Hazırlanıyor)',
          description: 'Kargo: ${s.kargofirmasi ?? "-"} | Takip: ${s.takipno ?? "-"}${s.aciklama != null && s.aciklama!.isNotEmpty ? '\nNot: ${s.aciklama}' : ''}',
          icon: Icons.inventory_2_rounded,
          color: Colors.blueAccent,
        ));

        if (s.sevkiyatdurumu >= 2 && s.sevkiyatdurumu != 4) {
            rawEvents.add(TimelineEvent(
              date: gonderildiDt,
              title: '$prefix (Gönderildi)',
              description: 'Kargo: ${s.kargofirmasi ?? "-"} | Takip: ${s.takipno ?? "-"}${s.aciklama != null && s.aciklama!.isNotEmpty ? '\nNot: ${s.aciklama}' : ''}',
              icon: Icons.local_shipping_rounded,
              color: Colors.orange,
            ));
        }

        if (s.sevkiyatdurumu == 3) {
            rawEvents.add(TimelineEvent(
              date: teslimDt,
              title: '$prefix (Teslim Edildi)',
              description: 'Kargo: ${s.kargofirmasi ?? "-"} | Takip: ${s.takipno ?? "-"}${s.aciklama != null && s.aciklama!.isNotEmpty ? '\nNot: ${s.aciklama}' : ''}',
              icon: Icons.check_circle_rounded,
              color: AppTheme.successGreen,
            ));
        }
        
        if (s.sevkiyatdurumu == 4) {
            rawEvents.add(TimelineEvent(
              date: iadeDt,
              title: '$prefix (İade Edildi)',
              description: 'Kargo: ${s.kargofirmasi ?? "-"} | Takip: ${s.takipno ?? "-"}${s.aciklama != null && s.aciklama!.isNotEmpty ? '\nNot: ${s.aciklama}' : ''}',
              icon: Icons.assignment_return_rounded,
              color: AppTheme.errorRed,
            ));
        }
      }

      // 4. Montajlar (Ana Cihaz olarak)
      for (var m in anacihazMontajlari) {
        DateTime? takilmaDt;
        DateTime? sokulmeDt;

        if (m.sokulmetarihi != null) {
           sokulmeDt = DateTime.tryParse(m.sokulmetarihi!);
        }

        final logs = montajLogs[m.id] ?? [];
        final eklemeLogs = logs.where((l) => l.islem == 'ekleme').toList();
        if (eklemeLogs.isNotEmpty && eklemeLogs.first.kgt != null) {
          takilmaDt = DateTime.tryParse(eklemeLogs.first.kgt!);
        } else if (m.kgt != null) {
          takilmaDt = DateTime.tryParse(m.kgt!);
        }


        rawEvents.add(TimelineEvent(
          date: takilmaDt,
          title: 'Bileşen Takıldı',
          description: 'Takılan: ${m.bilesenurunad ?? "?"} (SN: ${m.displayBilesenSeriNo})',
          icon: Icons.link_rounded,
          color: Colors.teal,
        ));

        // Sökülme olayı (sokulmetarihi)
        if (!m.isAktif) {
          rawEvents.add(TimelineEvent(
            date: sokulmeDt,
            title: 'Bileşen Söküldü',
            description: 'Sökülen: ${m.bilesenurunad ?? "?"} (SN: ${m.displayBilesenSeriNo})',
            icon: Icons.link_off_rounded,
            color: Colors.grey,
          ));
        }
      }

      // 5. Montajlar (Bileşen Cihaz olarak)
      for (var m in bilesenMontajlari) {
        DateTime? takilmaDt;
        DateTime? sokulmeDt;

        if (m.sokulmetarihi != null) {
          sokulmeDt = DateTime.tryParse(m.sokulmetarihi!);
        }

        final logs = montajLogs[m.id] ?? [];
        final eklemeLogs = logs.where((l) => l.islem == 'ekleme').toList();
        if (eklemeLogs.isNotEmpty && eklemeLogs.first.kgt != null) {
          takilmaDt = DateTime.tryParse(eklemeLogs.first.kgt!);
        } else if (m.kgt != null) {
          takilmaDt = DateTime.tryParse(m.kgt!);
        }


        rawEvents.add(TimelineEvent(
          date: takilmaDt,
          title: 'Ana Cihaza Takıldı',
          description: 'Ana Cihaz: ${m.anaurunad ?? "?"} (SN: ${m.displayAnaSeriNo})',
          icon: Icons.settings_input_component_rounded,
          color: Colors.teal,
        ));

        // Sökülme olayı
        if (!m.isAktif) {
          rawEvents.add(TimelineEvent(
            date: sokulmeDt,
            title: 'Ana Cihazdan Söküldü',
            description: 'Ana Cihaz: ${m.anaurunad ?? "?"} (SN: ${m.displayAnaSeriNo})',
            icon: Icons.broken_image_rounded,
            color: Colors.grey,
          ));
        }
      }

      // Sıralama (En yeni en üstte)
      rawEvents.sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1; // Tarihsizler sona
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });

      if (mounted) {
        setState(() {
          _events = rawEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cihaz Geçmişi',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary(context),
      ),
      body: Column(
        children: [
          _buildDeviceHeader(),
          Expanded(child: _buildTimeline()),
        ],
      ),
    );
  }

  Widget _buildDeviceHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor(context),
            AppTheme.primaryColor(context).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor(context).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.devices_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.urun.ad,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SN: ${widget.cihaz.displaySeriNo}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.urun.kategori != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.urun.kategori!,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_isLoading) {
      return const ShimmerLoadingList();
    }
    if (_error != null) {
      return Center(
        child: Text('Hata: $_error', style: const TextStyle(color: AppTheme.errorRed)),
      );
    }
    if (_events.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history_rounded,
        title: 'Geçmiş Bulunamadı',
        subtitle: 'Bu cihaza ait geçmiş kayıt bulunmuyor.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        final isLast = index == _events.length - 1;

        return IntrinsicHeight(
          child: Row(
            children: [
              // Sol taraf - İkon ve çizgi
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: event.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: event.color.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Icon(event.icon, color: event.color, size: 20),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppTheme.inputBorderColor(context),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Sağ taraf - Kart içeriği
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.inputBorderColor(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (event.date != null)
                            Text(
                              DateFormatUtils.formatDateTime(event.date!.toIso8601String()),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: event.color,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary(context),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
