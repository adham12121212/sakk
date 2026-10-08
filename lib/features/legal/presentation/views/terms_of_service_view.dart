import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/app_localizations.dart';

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final sections = isArabic ? _arSections : _enSections;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsOfService),
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

// Same disclaimer as privacy_policy_view.dart: fill in the bracketed
// placeholders, and treat this as a solid starting draft rather than a
// substitute for your own legal review.
const List<_LegalSection> _enSections = [
  _LegalSection(
    'Acceptance of these terms',
    'By creating an account or using Sakk, you agree to these Terms of '
        'Service. If you don\'t agree, please don\'t use the app.',
  ),
  _LegalSection(
    'What Sakk does',
    'Sakk helps you track purchases, warranties, and receipts, and offers '
        'an AI assistant for related questions. AI-generated responses and '
        'automatically extracted receipt data can be inaccurate — always '
        'check your original manufacturer or retailer documentation before '
        'relying on warranty dates or coverage.',
  ),
  _LegalSection(
    'Your account',
    'You\'re responsible for keeping your login credentials secure and for '
        'all activity that happens under your account. Provide accurate '
        'information when you sign up.',
  ),
  _LegalSection(
    'Acceptable use',
    'Don\'t use Sakk for anything unlawful, fraudulent, or abusive, and '
        'don\'t try to disrupt, reverse-engineer, or gain unauthorized '
        'access to the app or its backend systems.',
  ),
  _LegalSection(
    'Your content',
    'You keep ownership of the product information and photos you upload. '
        'By uploading them, you give us permission to store and process '
        'them solely to provide the app\'s features to you.',
  ),
  _LegalSection(
    'No warranty',
    'Sakk is provided "as is." We don\'t guarantee the app will be '
        'error-free, uninterrupted, or that AI-generated or extracted '
        'information will be accurate or complete.',
  ),
  _LegalSection(
    'Limitation of liability',
    'To the extent permitted by law, we are not liable for indirect, '
        'incidental, or consequential damages arising from your use of '
        'the app, including decisions made based on warranty information '
        'shown in it.',
  ),
  _LegalSection(
    'Termination',
    'We may suspend or terminate accounts that violate these terms.',
  ),
  _LegalSection(
    'Changes to these terms',
    'We may update these terms from time to time. Continuing to use Sakk '
        'after a change means you accept the updated terms.',
  ),
  _LegalSection(
    'Governing law',
    'These terms are governed by the laws of [Your Country/State].',
  ),
  _LegalSection(
    'Contact us',
    'Questions about these terms can be sent to [support email].',
  ),
];

const List<_LegalSection> _arSections = [
  _LegalSection(
    'الموافقة على هذه الشروط',
    'بإنشائك حسابًا أو استخدامك لتطبيق صك، فإنك توافق على شروط الخدمة '
        'هذه. إذا كنت لا توافق، فيُرجى عدم استخدام التطبيق.',
  ),
  _LegalSection(
    'ما يقدّمه صك',
    'يساعدك صك على تتبّع مشترياتك وضماناتك وفواتيرك، ويقدّم مساعدًا '
        'ذكيًا للأسئلة المرتبطة بذلك. قد تكون ردود المساعد الذكي '
        'والبيانات المستخرجة تلقائيًا من الفواتير غير دقيقة — تحقق دائمًا '
        'من وثائق الشركة المصنّعة أو المتجر الأصلية قبل الاعتماد على '
        'تواريخ أو تغطية الضمان.',
  ),
  _LegalSection(
    'حسابك',
    'أنت مسؤول عن الحفاظ على سرية بيانات تسجيل دخولك وعن كل نشاط يحدث '
        'تحت حسابك. يُرجى تقديم معلومات صحيحة عند التسجيل.',
  ),
  _LegalSection(
    'الاستخدام المقبول',
    'لا تستخدم صك في أي شيء غير قانوني أو احتيالي أو مسيء، ولا تحاول '
        'تعطيل التطبيق أو الهندسة العكسية له أو الوصول غير المصرّح به '
        'إليه أو إلى الأنظمة الخلفية له.',
  ),
  _LegalSection(
    'محتواك',
    'تحتفظ بملكية بيانات المنتجات والصور التي ترفعها. برفعك لها، فإنك '
        'تمنحنا إذنًا بتخزينها ومعالجتها فقط لتقديم ميزات التطبيق لك.',
  ),
  _LegalSection(
    'عدم وجود ضمان',
    'يُقدَّم صك "كما هو". لا نضمن أن يكون التطبيق خاليًا من الأخطاء أو '
        'بدون انقطاع، ولا نضمن دقة أو اكتمال المعلومات المولّدة أو '
        'المستخرجة بالذكاء الاصطناعي.',
  ),
  _LegalSection(
    'حدود المسؤولية',
    'إلى الحد الذي يسمح به القانون، لا نتحمّل المسؤولية عن أي أضرار '
        'غير مباشرة أو عرضية أو تبعية ناتجة عن استخدامك للتطبيق، بما في '
        'ذلك القرارات المتخذة بناءً على معلومات الضمان المعروضة فيه.',
  ),
  _LegalSection(
    'إنهاء الحساب',
    'يجوز لنا تعليق أو إنهاء الحسابات التي تخالف هذه الشروط.',
  ),
  _LegalSection(
    'التغييرات على هذه الشروط',
    'قد نحدّث هذه الشروط من وقت لآخر. استمرارك في استخدام صك بعد أي '
        'تغيير يعني قبولك للشروط المحدّثة.',
  ),
  _LegalSection(
    'القانون الحاكم',
    'تخضع هذه الشروط لقوانين [بلدك/ولايتك].',
  ),
  _LegalSection(
    'تواصل معنا',
    'يمكن إرسال أي أسئلة حول هذه الشروط إلى [البريد الإلكتروني للدعم].',
  ),
];
