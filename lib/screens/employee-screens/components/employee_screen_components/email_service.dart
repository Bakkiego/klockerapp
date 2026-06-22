import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  static Future<bool> sendApprovalEmail({
    required String employeeEmail,
    required String employeeName,
  }) async {
    try {
      // 🚀 Tell Supabase to run our Edge Function
      final response = await Supabase.instance.client.functions.invoke(
        'send-approval-email',
        body: {'employeeEmail': employeeEmail, 'employeeName': employeeName},
      );

      // The status code comes back from our Deno code
      if (response.status == 200) {
        debugPrint("Edge Function Success: Email sent to $employeeEmail");
        return true;
      } else {
        debugPrint("Edge Function Failed: ${response.data}");
        return false;
      }
    } on FunctionException catch (e) {
      // 🚀 Changed from e.reason to e.details and e.status
      debugPrint(
        "Edge Function Error [${e.status}]: ${e.details ?? e.reasonPhrase}",
      );
      return false;
    } catch (e) {
      debugPrint("System Error calling Edge Function: $e");
      return false;
    }
  }
}
