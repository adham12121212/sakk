import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/app_localizations.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final sections = isArabic ? _arSections : _enSections;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'آخر تحديث: [أضف التاريخ هنا]' : 'Last updated: [add date here]',
                style: TextStyle(fontSize: 12.sp, color: colorScheme.onSurface.withOpacity(0.5)),
              ),
              SizedBox(height: 20.h),
              for (final section in sections) ...[
                Text(
                  section.heading,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
                SizedBox(height: 6.h),
                Text(
                  section.body,
                  style: TextStyle(fontSize: 14.sp, height: 1.5, color: colorScheme.onSurface.withOpacity(0.8)),
                ),
                SizedBox(height: 18.h),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

// NOTE: replace the bracketed placeholders ([support email],
// [Your Country/State], the "last updated" date above) with your real
// details before shipping. This covers the substance Google Play
// expects, but it is not a substitute for your own legal review —
// especially the governing-law and liability sections.
const List<_LegalSection> _enSections = [
  _LegalSection(
    'Introduction',
    'Sakk ("we", "us", or "our") provides an app that helps you track your '
        'purchases, warranties, and receipts, including an AI assistant for '
        'related questions. This policy explains what information we '
        'collect, how we use it, and the choices you have.',
  ),
  _LegalSection(
    'Information we collect',
    'Account information: your email address, name, and an optional profile '
        'photo. Product data you enter: names, brands, prices, purchase '
        'dates, warranty lengths, notes, categories, and any photos of '
        'receipts or products you upload. Messages you send to the AI '
        'assistant. Basic profile information from Google if you sign in '
        'with Google.',
  ),
  _LegalSection(
    'How we use your information',
    'To provide and maintain the app, generate responses from the AI '
        'assistant, calculate and remind you about warranty status, and '
        'improve the app over time. We do not sell your personal '
        'information.',
  ),
  _LegalSection(
    'Third-party services we use',
    'Supabase provides authentication, our database, and file storage for '
        'photos you upload. A third-party AI provider processes your chat '
        'messages and scanned receipt images to generate responses and '
        'extract product details. If you sign in with Google, Google '
        'processes that sign-in. Each provider handles data under its own '
        'privacy policy.',
  ),
  _LegalSection(
    'Data storage and security',
    'Your data is stored with our backend provider using industry-standard '
        'security practices. No method of electronic storage or '
        'transmission is completely secure, and we cannot guarantee '
        'absolute security.',
  ),
  _LegalSection(
    'Biometric authentication',
    'If you enable Face ID / fingerprint unlock, that check happens '
        'entirely on your device using your operating system\'s own '
        'biometric APIs. We never receive, see, transmit, or store your '
        'biometric data.',
  ),
  _LegalSection(
    'Data retention and deletion',
    'You can delete individual products and notifications directly in the '
        'app at any time. To delete your account and all associated data, '
        'contact us at [support email] and we will process your request '
        'within a reasonable time.',
  ),
  _LegalSection(
    'Children\'s privacy',
    'Sakk is not directed to children under 13, and we do not knowingly '
        'collect personal information from children.',
  ),
  _LegalSection(
    'Your rights',
    'Depending on where you live, you may have rights to access, correct, '
        'or delete your personal data, or to object to certain processing. '
        'Contact us using the details below to exercise these rights.',
  ),
  _LegalSection(
    'Changes to this policy',
    'We may update this policy from time to time. Continuing to use Sakk '
        'after a change means you accept the updated policy.',
  ),
  _LegalSection(
    'Contact us',
    'Questions about this policy or your data can be sent to '
        '[support email].',
  ),
];

const List<_LegalSection> _arSections = [
  _LegalSection(
    'مقدمة',
    'يقدّم تطبيق "صك" ("نحن") تجربة لتتبّع مشترياتك وضماناتك وفواتيرك، '
        'بما في ذلك مساعد ذكاء اصطناعي للأسئلة المرتبطة بذلك. توضّح هذه '
        'السياسة ما هي المعلومات التي نجمعها، وكيف نستخدمها، والخيارات '
        'المتاحة لك.',
  ),
  _LegalSection(
    'المعلومات التي نجمعها',
    'معلومات الحساب: بريدك الإلكتروني، اسمك، وصورة الملف الشخصي (اختياري). '
        'بيانات المنتجات التي تُدخلها: الأسماء، الماركات، الأسعار، تواريخ '
        'الشراء، مدة الضمان، الملاحظات، الفئات، وأي صور فواتير أو منتجات '
        'ترفعها. الرسائل التي ترسلها للمساعد الذكي. معلومات أساسية من '
        'حسابك في جوجل إذا سجّلت الدخول به.',
  ),
  _LegalSection(
    'كيف نستخدم معلوماتك',
    'لتقديم التطبيق وصيانته، وتوليد ردود المساعد الذكي، وحساب حالة الضمان '
        'وتذكيرك بها، وتحسين التطبيق باستمرار. لا نبيع معلوماتك الشخصية '
        'لأي طرف آخر.',
  ),
  _LegalSection(
    'خدمات طرف ثالث نستخدمها',
    'يوفّر لنا Supabase المصادقة وقاعدة البيانات وتخزين الصور التي ترفعها. '
        'يعالج مزوّد ذكاء اصطناعي خارجي رسائل الدردشة وصور الفواتير '
        'الممسوحة لتوليد الردود واستخراج تفاصيل المنتج. إذا سجّلت الدخول '
        'بحساب جوجل، فإن جوجل هي من يعالج ذلك الدخول. يخضع كل مزوّد '
        'لسياسة الخصوصية الخاصة به.',
  ),
  _LegalSection(
    'تخزين البيانات وأمانها',
    'تُخزَّن بياناتك عند مزوّد خدمتنا الخلفية باستخدام ممارسات أمان '
        'قياسية في هذا المجال. لا توجد وسيلة تخزين أو نقل إلكتروني مضمونة '
        'الأمان بشكل كامل، ولا يمكننا ضمان أمان مطلق.',
  ),
  _LegalSection(
    'المصادقة البيومترية',
    'إذا فعّلت فتح التطبيق ببصمة الإصبع أو Face ID، فإن هذا التحقق يتم '
        'بالكامل على جهازك باستخدام واجهات نظام التشغيل البيومترية. لا '
        'نستقبل أو نرى أو ننقل أو نخزّن بياناتك البيومترية أبدًا.',
  ),
  _LegalSection(
    'الاحتفاظ بالبيانات وحذفها',
    'يمكنك حذف المنتجات والإشعارات الفردية من داخل التطبيق في أي وقت. '
        'لحذف حسابك وكل البيانات المرتبطة به، تواصل معنا على '
        '[البريد الإلكتروني للدعم] وسنعالج طلبك في وقت معقول.',
  ),
  _LegalSection(
    'خصوصية الأطفال',
    'تطبيق "صك" غير موجّه للأطفال دون 13 عامًا، ولا نجمع معلومات شخصية '
        'من الأطفال عن علم.',
  ),
  _LegalSection(
    'حقوقك',
    'بحسب مكان إقامتك، قد يكون لك حق الوصول إلى بياناتك الشخصية أو '
        'تصحيحها أو حذفها، أو الاعتراض على معالجتها. تواصل معنا عبر '
        'بيانات الاتصال أدناه لممارسة هذه الحقوق.',
  ),
  _LegalSection(
    'التغييرات على هذه السياسة',
    'قد نحدّث هذه السياسة من وقت لآخر. استمرارك في استخدام صك بعد أي '
        'تغيير يعني قبولك للسياسة المحدّثة.',
  ),
  _LegalSection(
    'تواصل معنا',
    'يمكن إرسال أي أسئلة حول هذه السياسة أو بياناتك إلى '
        '[البريد الإلكتروني للدعم].',
  ),
];
