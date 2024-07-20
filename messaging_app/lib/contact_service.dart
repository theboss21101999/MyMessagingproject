import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  Future<bool> hasContact(String phoneNumber) async {
    if (await Permission.contacts.request().isGranted) {
      Iterable<Contact> contacts = await ContactsService.getContacts();
      for (Contact contact in contacts) {
        for (Item phone in contact.phones!) {
          if (phone.value == phoneNumber) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
