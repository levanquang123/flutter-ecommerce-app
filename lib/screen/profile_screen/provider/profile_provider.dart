import 'package:flutter/cupertino.dart';

import '../../../models/address.dart';
import '../../../services/http_services.dart';
import '../../../utility/snack_bar_helper.dart';
import '../../login_screen/provider/user_provider.dart';

class ProfileProvider extends ChangeNotifier {
  final UserProvider _userProvider;
  final HttpService _service = HttpService();

  final GlobalKey<FormState> addressFormKey = GlobalKey<FormState>();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController streetController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController postalCodeController = TextEditingController();
  TextEditingController countryController = TextEditingController();

  ProfileProvider(this._userProvider) {
    fillControllersFromCurrentUser();
  }

  void fillControllersFromCurrentUser() {
    fillControllers(_userProvider.currentUser?.address);
  }

  void fillControllers(Address? address) {
    fullNameController.text = address?.fullName ?? '';
    phoneController.text = address?.phone ?? '';
    streetController.text = address?.street ?? '';
    cityController.text = address?.city ?? '';
    stateController.text = address?.state ?? '';
    postalCodeController.text = address?.postalCode ?? '';
    countryController.text = address?.country ?? '';
    notifyListeners();
  }

  void clearAddressForm() {
    fullNameController.clear();
    phoneController.clear();
    streetController.clear();
    cityController.clear();
    stateController.clear();
    postalCodeController.clear();
    countryController.clear();
    notifyListeners();
  }

  Map<String, dynamic> _addressPayload() {
    return {
      'fullName': fullNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'street': streetController.text.trim(),
      'city': cityController.text.trim(),
      'state': stateController.text.trim(),
      'postalCode': postalCodeController.text.trim(),
      'country': countryController.text.trim(),
    };
  }

  Future<bool> updateAddress() async {
    try {
      final response = await _service.putItem(
        endpointUrl: 'users/me/address',
        itemData: _addressPayload(),
      );

      if (!response.isOk) {
        SnackBarHelper.showErrorSnackBar(
          HttpService.parseResponseMessage(
            response,
            fallback: 'Unable to update address. Please try again.',
          ),
        );
        return false;
      }

      await _userProvider.fetchCurrentUserProfile(showSnack: false);
      fillControllersFromCurrentUser();
      SnackBarHelper.showSuccessSnackBar('Address updated successfully');
      return true;
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
        HttpService.humanizeError(
          e,
          fallback: 'Unable to update address right now. Please try again.',
        ),
      );
      return false;
    }
  }
}
