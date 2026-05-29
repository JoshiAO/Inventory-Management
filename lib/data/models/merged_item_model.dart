import 'item_model.dart';
import 'price_model.dart';
import 'ssr_baseline_model.dart';
import 'count_model.dart';

class MergedItem {
  final ItemMaster master;
  final PriceList? price;
  final SsrBaseline? ssr;
  final CountModel? count;

  MergedItem({
    required this.master,
    this.price,
    this.ssr,
    this.count,
  });

  double get ssrValue {
    if (price == null || ssr == null) return 0.0;
    return (ssr!.ssrCase * price!.priceCase) +
           (ssr!.ssrSubcase * price!.priceSubcase) +
           (ssr!.ssrPiece * price!.pricePiece);
  }

  double get countValue {
    if (price == null || count == null) return 0.0;
    return (count!.quantities.countCase * price!.priceCase) +
           (count!.quantities.countSubcase * price!.priceSubcase) +
           (count!.quantities.countPiece * price!.pricePiece);
  }

  double get discrepancyValue => countValue - ssrValue;

  String get status {
    if (discrepancyValue > 0) return 'Over';
    if (discrepancyValue < 0) return 'Short';
    return 'Balanced';
  }
}
