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
                isArabic ? 'آخر تحديث: 11 أكتوبر 2026' : 'Last updated: October 11, 2026',
                style: TextStyle(fontSize: 12.sp, color: colorScheme.onSurface.withValues(alpha: 0.5)),
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
                  style: TextStyle(fontSize: 14.sp, height: 1.5, color: colorScheme.onSurface.withValues(alpha: 0.8)),
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

const List<_LegalSection> _enSections = [
  _LegalSection(
    'Introduction',
    'Sakk ("we", "us", or "our") provides an app that helps you track your '
        'purchases, warranties, returns and receipts, including an AI assistant '
        'for related questions. This policy explains what information we '
        'collect, how we use it, and the choices you have.',
  ),
  _LegalSection(
    'Information we collect',
    'Account information: your email address, name, and an optional profile '
        'photo. Basic profile information from Google if you sign in with '
        'Google.\n\n'
        'Product data you enter or scan: names, brands, stores, prices, purchase '
        'dates, warranty lengths, extra warranties, return windows, serial and '
        'invoice numbers, notes, categories, warranty claims you record, and the '
        'photos and documents you add (receipts, PDF invoices, warranty cards, '
        'product photos, manuals).\n\n'
        'Family sharing: the household you create or join and the name other '
        'members see.\n\n'
        'Messages you send to the AI assistant.\n\n'
        'Technical data: crash reports when the app fails (see below).',
  ),
  _LegalSection(
    'How we use your information',
    'To provide and maintain the app; to read the details from receipts and '
        'invoices you scan; to answer your questions in the AI assistant; to '
        'calculate warranty status and remind you before warranties end and '
        'return windows close; to show your products to your household if you '
        'join one; and to find and fix problems. We do not sell your personal '
        'information.',
  ),
  _LegalSection(
    'Family sharing',
    'If you create or join a household, its other members can see your '
        'products, including prices, receipts, documents, extra warranties and '
        'claims, together with the name you chose. Only you can change or '
        'delete your products. You can leave a household at any time from '
        'Profile; members then stop seeing your products and you stop seeing '
        'theirs. A household owner can remove members.',
  ),
  _LegalSection(
    'The AI assistant and receipt scanning',
    'To read a receipt or invoice, the photo (and, for PDFs, the text of the '
        'invoice) is sent to our AI provider. To answer your questions, the AI '
        'assistant receives your message, recent messages in the conversation, '
        'and the details of the products you can see in the app (yours and, if '
        'you are in a household, your household\'s). AI answers can be wrong; '
        'check important details such as dates yourself.',
  ),
  _LegalSection(
    'Third-party services we use',
    'Supabase provides sign-in, our database, file storage and the server '
        'functions that talk to the AI provider. Groq (our current AI provider) '
        'processes scanned receipts and assistant messages as described above. '
        'Sentry receives crash reports; before a report leaves your device we '
        'remove email addresses and private links. Google processes Google '
        'sign-in, and Firebase provides app services. Each provider handles '
        'data under its own privacy policy.',
  ),
  _LegalSection(
    'Device permissions',
    'Camera and photos: only when you scan a receipt or add a document. Files: '
        'only the PDF you pick. Notifications: for warranty and return '
        'reminders. Calendar: only when you tap "Add to calendar", which opens '
        'your calendar app with the event for you to save. On iPhone, the '
        'calendar\'s own screen may offer place suggestions from your contacts; '
        'Sakk itself does not read your contacts. Face ID / fingerprint: see '
        'below.',
  ),
  _LegalSection(
    'Data on your device',
    'To work offline and remind you on time, the app keeps a copy of your '
        'product list, your reminder and display settings, and scheduled '
        'reminders on your device. Signing out removes your product list and '
        'reminders from the device.',
  ),
  _LegalSection(
    'Data storage and security',
    'Your data is stored with our backend provider. Each user\'s data is '
        'protected so that only you (and, for products, your household) can '
        'see it, and only you can change it. No method of electronic storage '
        'or transmission is completely secure, and we cannot guarantee '
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
    'You can delete products, documents, claims and notifications in the app '
        'at any time; deleting a product also deletes its photos and '
        'documents. You can export your products as a spreadsheet from the '
        'Products screen. To delete your account and all associated data, use '
        'Profile > Delete account; this removes your products, photos, '
        'documents, notifications and household membership. You can also '
        'contact us at dev.adhamelnagar7@gmail.com.',
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
        'dev.adhamelnagar7@gmail.com.',
  ),
];

const List<_LegalSection> _arSections = [
  _LegalSection(
    'مقدمة',
    'يقدّم تطبيق "صك" ("نحن") تجربة لتتبّع مشترياتك وضماناتك ومواعيد '
        'الاسترجاع وفواتيرك، بما في ذلك مساعد ذكاء اصطناعي للأسئلة المرتبطة '
        'بذلك. توضّح هذه السياسة ما هي المعلومات التي نجمعها، وكيف نستخدمها، '
        'والخيارات المتاحة لك.',
  ),
  _LegalSection(
    'المعلومات التي نجمعها',
    'معلومات الحساب: بريدك الإلكتروني، اسمك، وصورة الملف الشخصي (اختياري). '
        'معلومات أساسية من حسابك في جوجل إذا سجّلت الدخول به.\n\n'
        'بيانات المنتجات التي تُدخلها أو تمسحها: الأسماء، الماركات، المتاجر، '
        'الأسعار، تواريخ الشراء، مدة الضمان، الضمانات الإضافية، مدة الاسترجاع، '
        'الأرقام التسلسلية وأرقام الفواتير، الملاحظات، الفئات، طلبات الضمان '
        'التي تسجّلها، والصور والمستندات التي تضيفها (الفواتير، فواتير PDF، '
        'بطاقات الضمان، صور المنتجات، أدلة الاستخدام).\n\n'
        'المشاركة العائلية: العائلة التي تنشئها أو تنضم إليها، والاسم الذي '
        'يراه بقية الأعضاء.\n\n'
        'الرسائل التي ترسلها للمساعد الذكي.\n\n'
        'بيانات تقنية: تقارير الأعطال عند حدوث خطأ في التطبيق (انظر أدناه).',
  ),
  _LegalSection(
    'كيف نستخدم معلوماتك',
    'لتقديم التطبيق وصيانته؛ ولقراءة التفاصيل من الفواتير التي تمسحها؛ '
        'وللإجابة عن أسئلتك في المساعد الذكي؛ ولحساب حالة الضمان وتذكيرك قبل '
        'انتهاء الضمانات ومواعيد الاسترجاع؛ ولعرض منتجاتك على عائلتك إذا '
        'انضممت إلى عائلة؛ ولاكتشاف المشكلات وإصلاحها. لا نبيع معلوماتك '
        'الشخصية لأي طرف آخر.',
  ),
  _LegalSection(
    'المشاركة العائلية',
    'إذا أنشأت عائلة أو انضممت إليها، يستطيع بقية أعضائها رؤية منتجاتك، بما '
        'في ذلك الأسعار والفواتير والمستندات والضمانات الإضافية وطلبات الضمان، '
        'مع الاسم الذي اخترته. أنت وحدك من يستطيع تعديل منتجاتك أو حذفها. '
        'يمكنك مغادرة العائلة في أي وقت من الملف الشخصي، وعندها يتوقف الأعضاء '
        'عن رؤية منتجاتك وتتوقف أنت عن رؤية منتجاتهم. يستطيع مالك العائلة '
        'إزالة الأعضاء.',
  ),
  _LegalSection(
    'المساعد الذكي ومسح الفواتير',
    'لقراءة فاتورة، تُرسَل الصورة (ونص الفاتورة في حالة ملفات PDF) إلى مزوّد '
        'الذكاء الاصطناعي. وللإجابة عن أسئلتك، يتلقى المساعد رسالتك والرسائل '
        'الأخيرة في المحادثة وتفاصيل المنتجات التي تراها في التطبيق (منتجاتك '
        'ومنتجات عائلتك إذا كنت في عائلة). قد تكون إجابات الذكاء الاصطناعي '
        'خاطئة، فتحقق بنفسك من التفاصيل المهمة مثل التواريخ.',
  ),
  _LegalSection(
    'خدمات طرف ثالث نستخدمها',
    'يوفّر Supabase تسجيل الدخول وقاعدة البيانات وتخزين الملفات ووظائف '
        'الخادم التي تتواصل مع مزوّد الذكاء الاصطناعي. تعالج Groq (مزوّد الذكاء '
        'الاصطناعي الحالي) الفواتير الممسوحة ورسائل المساعد كما هو موضّح أعلاه. '
        'تستقبل Sentry تقارير الأعطال، ونزيل منها عناوين البريد والروابط الخاصة '
        'قبل أن تغادر جهازك. تعالج جوجل تسجيل الدخول بحساب جوجل، وتوفّر Firebase '
        'خدمات للتطبيق. يخضع كل مزوّد لسياسة الخصوصية الخاصة به.',
  ),
  _LegalSection(
    'أذونات الجهاز',
    'الكاميرا والصور: فقط عند مسح فاتورة أو إضافة مستند. الملفات: فقط ملف '
        'PDF الذي تختاره. الإشعارات: لتذكيرات الضمان والاسترجاع. التقويم: فقط '
        'عند الضغط على "إضافة إلى التقويم"، فيُفتح تطبيق التقويم بالحدث لتحفظه '
        'بنفسك. على iPhone قد تقترح شاشة التقويم أماكن من جهات اتصالك، أما صك '
        'نفسه فلا يقرأ جهات اتصالك. البصمة وFace ID: انظر أدناه.',
  ),
  _LegalSection(
    'البيانات على جهازك',
    'ليعمل التطبيق دون اتصال ويذكّرك في الوقت المناسب، يحتفظ على جهازك بنسخة '
        'من قائمة منتجاتك وإعدادات التذكير والعرض والتذكيرات المجدولة. تسجيل '
        'الخروج يحذف قائمة منتجاتك وتذكيراتك من الجهاز.',
  ),
  _LegalSection(
    'تخزين البيانات وأمانها',
    'تُخزَّن بياناتك عند مزوّد خدمتنا الخلفية، وتُحمى بحيث لا يراها إلا أنت '
        '(وعائلتك بالنسبة للمنتجات)، ولا يعدّلها أحد غيرك. لا توجد وسيلة تخزين '
        'أو نقل إلكتروني مضمونة الأمان بشكل كامل، ولا يمكننا ضمان أمان مطلق.',
  ),
  _LegalSection(
    'المصادقة البيومترية',
    'إذا فعّلت فتح التطبيق ببصمة الإصبع أو Face ID، فإن هذا التحقق يتم '
        'بالكامل على جهازك باستخدام واجهات نظام التشغيل البيومترية. لا '
        'نستقبل أو نرى أو ننقل أو نخزّن بياناتك البيومترية أبدًا.',
  ),
  _LegalSection(
    'الاحتفاظ بالبيانات وحذفها',
    'يمكنك حذف المنتجات والمستندات وطلبات الضمان والإشعارات من داخل التطبيق '
        'في أي وقت، وحذف المنتج يحذف صوره ومستنداته أيضًا. يمكنك تصدير منتجاتك '
        'كجدول بيانات من شاشة المنتجات. لحذف حسابك وكل البيانات المرتبطة به، '
        'استخدم الملف الشخصي > حذف الحساب، فيُحذف معه منتجاتك وصورك ومستنداتك '
        'وإشعاراتك وعضويتك في العائلة. ويمكنك أيضًا التواصل معنا على '
        'dev.adhamelnagar7@gmail.com.',
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
        'dev.adhamelnagar7@gmail.com.',
  ),
];
