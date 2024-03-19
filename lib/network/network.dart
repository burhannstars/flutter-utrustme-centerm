class NetworkUrl {
  static String url = "https://www.gudangvoucher.com/edc/api";
  static String developmentURL = "http://localhost";

  static String piURL = "http://10.10.10.96";

  static String devURL = "http://10.10.10.30";

  //Development on Localhost

  static String checkTimbanganToken() {
    return "$devURL/timbangan/checkToken.php";
  }

  static String checkOTP() {
    return "$url/checkOTP.php";
  }

  static String resendOTP() {
    return "$url/resendOTP.php";
  }

  static String checkVATRX() {
    return "$url/getPrintBank.php";
  }

  //End Development

  static String addProduct() {
    return "$url/addProduct.php";
  }

  static String addCategory() {
    return "$url/addCategory.php";
  }

  static String editProduct() {
    return "$url/editProduct.php";
  }

  static String editCategory() {
    return "$url/editCategory.php";
  }

  static String editOrderNote() {
    return "$url/editOrderNote.php";
  }

  static String addToCart() {
    return "$url/addToCart.php";
  }

  static String emptyCart() {
    return "$url/deleteCart.php";
  }

  static String getProduct() {
    return "$url/getProduct.php";
  }

  static String getCategory() {
    return "$url/getCategory.php";
  }

  static String getProductCart() {
    return "$url/getProductCart.php";
  }

  static String getProductWithCategory() {
    return "$url/getProductWithCategory.php";
  }

  static String getProductCat() {
    return "$url/getProductCat.php";
  }

  static String getTotalCart() {
    return "$url/getTotalCart.php";
  }

  static String getSalesReport() {
    return "$url/getReport.php";
  }

  static String getTodaySalesReport() {
    return "$url/getTodayReport.php";
  }

  static String getPaidSalesReport() {
    return "$url/getPaidReport.php";
  }

  static String getUnpaidSalesReport() {
    return "$url/getUnpaidReport.php";
  }

  static String getDateReport() {
    return "$url/getDateReport.php";
  }

  static String getSummaryCart() {
    return "$url/getSumCart.php";
  }

  static String getQrisLastTRX() {
    return "$url/getQrisLastTRX.php";
  }

  static String getQRISdesc() {
    return "$url/getQRdesc.php";
  }

  static String getLastNotif() {
    return "$url/getLastNotif.php";
  }

  static String updateCart() {
    return "$url/updateCart.php";
  }

  static String checkoutCart() {
    return "$url/checkoutCart.php";
  }

  static String checkQRIStrx() {
    //return "$url/checkQRIStrx.php";
    return "$url/checkQRIStrx_new.php";
  }

  static String printQRISHistory() {
    return "$url/printQRIShistory.php";
  }

  static String cartItemDetail() {
    return "$url/getCartItem.php";
  }

  static String deleteProduct() {
    return "$url/deleteProduct.php";
  }

  static String deleteCategory() {
    return "$url/deleteCategory.php";
  }

  static String createTagihanDynamic() {
    return "https://www.gudangvoucher.com/payment_channel/gv_connect/qris/qr_acquirer";
  }

  static String cetakQR() {
    return "https://www.gudangvoucher.com/merchant/cetak.php?type=3&number=";
  }

  static String countTodaySales() {
    return "$url/countTodaySales.php";
  }

  static String getTodayReportCSV() {
    return "$url/getTodayReportCSV.php";
  }

  static String getMerchantBalance() {
    return "$url/getBalance.php";
  }

  static String streamQRIStrx() {
    return "$url/streamQRIStrx.php";
  }

  static String urlTransferDana() {
    return "https://www.gudangvoucher.com/edc/index.php?Settlement=1&Platform=scm";
  }

  static String urlBankTransfer() {
    return "https://www.gudangvoucher.com/edc/index.php?DynamicBank=1&Platform=scm";
  }

  static String urlHome() {
    return "https://www.gudangvoucher.com/edc/index.php?Platform=scm";
  }

  static String getPrintTransfer() {
    return "$url/getPrintTransfer.php";
  }
}
