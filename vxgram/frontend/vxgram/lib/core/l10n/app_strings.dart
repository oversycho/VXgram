import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// English + Farsi strings (keys match the Figma copy table). Add keys here, no codegen needed.
class AppStrings {
  AppStrings(this.locale);
  final Locale locale;
  bool get isFa => locale.languageCode == 'fa';

  static AppStrings of(BuildContext c) => Localizations.of<AppStrings>(c, AppStrings)!;
  static const LocalizationsDelegate<AppStrings> delegate = _Delegate();
  static const supported = [Locale('en'), Locale('fa')];

  String get(String k) => (_v[locale.languageCode] ?? _v['en']!)[k] ?? _v['en']![k] ?? k;

  String digits(String s) => isFa ? s.replaceAllMapped(RegExp(r'\d'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]) : s;

  /// 1234567 -> "1,234,567" / "۱٬۲۳۴٬۵۶۷"
  String n(num v) => digits(v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => isFa ? '٬' : ','));

  String fmt(String key, Map<String, Object> args) {
    var s = get(key);
    args.forEach((k, v) => s = s.replaceAll('{$k}', v is num ? n(v) : '$v'));
    return s;
  }

  String ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return get('now');
    if (diff.inHours < 1) return fmt('ago_m', {'n': diff.inMinutes});
    if (diff.inDays < 1) return fmt('ago_h', {'n': diff.inHours});
    return fmt('ago_d', {'n': diff.inDays});
  }

  static const _v = {
    'en': {
      'welcome': 'Welcome back', 'login': 'Log in', 'signup': 'Sign up', 'email': 'Email', 'password': 'Password',
      'forgot': 'Forgot password?', 'no_account': 'New to VXGram? Sign up', 'have_account': 'Already have an account? Log in',
      'create': 'Create account', 'username': 'Username', 'full_name': 'Full name',
      'username_rules': '3-30 characters: letters, numbers, . and _', 'username_available': 'Available', 'username_taken': 'Already taken',
      'required': 'Required', 'invalid_email': 'Enter a valid email', 'password_short': 'At least 6 characters',
      'reset_sent': 'Password reset email sent', 'confirm_email': 'Check your email to confirm your account',
      'home': 'Home', 'explore': 'Explore', 'post': 'New post', 'inbox': 'Inbox', 'profile': 'Profile',
      'likes_n': '{n} likes', 'view_comments_n': 'View all {n} comments', 'link_copied': 'Link copied',
      'delete_post': 'Delete post', 'delete_post_q': "Delete this post? This can't be undone.", 'cancel': 'Cancel', 'delete': 'Delete',
      'empty_feed': 'Follow people to see their posts', 'settings': 'Settings', 'language': 'Language', 'appearance': 'Appearance',
      'system': 'System', 'light': 'Light', 'dark': 'Dark', 'logout': 'Log out', 'continue': 'Continue',
      'choose_language': 'Choose your language', 'choose_look': 'Choose how VXGram looks', 'coming_soon': 'Coming in the next step',
      'now': 'now', 'ago_m': '{n}m ago', 'ago_h': '{n}h ago', 'ago_d': '{n}d ago', 'retry': 'Try again',
      'followers': 'Followers', 'following_label': 'Following', 'posts': 'Posts', 'follow': 'Follow', 'following': 'Following',
      'requested': 'Requested', 'follow_back': 'Follow back', 'edit_profile': 'Edit profile', 'private_title': 'This account is private',
      'private_body': 'Follow to see their photos and videos.', 'private_account': 'Private account',
      'private_help': 'Only people you approve can see your posts', 'follow_requests': 'Follow requests', 'confirm': 'Confirm',
      'no_requests': 'No pending requests', 'remove': 'Remove', 'change_photo': 'Change photo', 'bio': 'Bio', 'save': 'Save', 'name': 'Name',
      'no_posts': 'No posts yet', 'change_password': 'Change password', 'new_password': 'New password', 'confirm_password': 'Confirm new password',
      'update_password': 'Update password', 'password_updated': 'Password updated', 'passwords_mismatch': 'Passwords do not match',
      'unfollow_q': 'Unfollow {u}?', 'unfollow': 'Unfollow', 'profile_updated': 'Profile saved', 'no_followers': 'No followers yet',
      'no_following': 'Not following anyone yet', 'account': 'Account', 'privacy': 'Privacy', 'preferences': 'Preferences',
    },
    'fa': {
      'welcome': 'دوباره خوش آمدید', 'login': 'ورود', 'signup': 'ثبت‌نام', 'email': 'ایمیل', 'password': 'رمز عبور',
      'forgot': 'رمز عبور را فراموش کرده‌اید؟', 'no_account': 'در VXGram تازه‌اید؟ ثبت‌نام کنید', 'have_account': 'حساب دارید؟ وارد شوید',
      'create': 'ایجاد حساب', 'username': 'نام کاربری', 'full_name': 'نام و نام خانوادگی',
      'username_rules': '۳ تا ۳۰ نویسه: حروف انگلیسی، عدد، نقطه و زیرخط', 'username_available': 'قابل استفاده', 'username_taken': 'قبلاً گرفته شده',
      'required': 'الزامی است', 'invalid_email': 'ایمیل معتبر وارد کنید', 'password_short': 'حداقل ۶ نویسه',
      'reset_sent': 'ایمیل بازیابی رمز عبور ارسال شد', 'confirm_email': 'برای تأیید حساب، ایمیل خود را بررسی کنید',
      'home': 'خانه', 'explore': 'کاوش', 'post': 'پست جدید', 'inbox': 'صندوق ورودی', 'profile': 'پروفایل',
      'likes_n': '{n} لایک', 'view_comments_n': 'مشاهده همه {n} نظر', 'link_copied': 'لینک کپی شد',
      'delete_post': 'حذف پست', 'delete_post_q': 'این پست حذف شود؟ این کار قابل بازگشت نیست.', 'cancel': 'انصراف', 'delete': 'حذف',
      'empty_feed': 'برای دیدن پست‌ها، افراد را دنبال کنید', 'settings': 'تنظیمات', 'language': 'زبان', 'appearance': 'ظاهر',
      'system': 'سیستم', 'light': 'روشن', 'dark': 'تاریک', 'logout': 'خروج از حساب', 'continue': 'ادامه',
      'choose_language': 'زبان خود را انتخاب کنید', 'choose_look': 'حالت نمایش را انتخاب کنید', 'coming_soon': 'در مرحله بعد اضافه می‌شود',
      'now': 'اکنون', 'ago_m': '{n} دقیقه پیش', 'ago_h': '{n} ساعت پیش', 'ago_d': '{n} روز پیش', 'retry': 'تلاش دوباره',
      'followers': 'دنبال‌کننده', 'following_label': 'دنبال‌شونده', 'posts': 'پست', 'follow': 'دنبال کردن', 'following': 'دنبال می‌کنید',
      'requested': 'درخواست شد', 'follow_back': 'دنبال کردن متقابل', 'edit_profile': 'ویرایش پروفایل', 'private_title': 'این حساب خصوصی است',
      'private_body': 'برای دیدن عکس‌ها و ویدیوهای این حساب، آن را دنبال کنید.', 'private_account': 'حساب خصوصی',
      'private_help': 'فقط افرادی که تأیید می‌کنید می‌توانند پست‌های شما را ببینند.', 'follow_requests': 'درخواست‌های دنبال کردن', 'confirm': 'تأیید',
      'no_requests': 'درخواستی وجود ندارد', 'remove': 'حذف', 'change_photo': 'تغییر عکس', 'bio': 'بیوگرافی', 'save': 'ذخیره', 'name': 'نام',
      'no_posts': 'هنوز پستی وجود ندارد', 'change_password': 'تغییر رمز عبور', 'new_password': 'رمز عبور جدید', 'confirm_password': 'تکرار رمز عبور جدید',
      'update_password': 'به‌روزرسانی رمز عبور', 'password_updated': 'رمز عبور تغییر کرد', 'passwords_mismatch': 'رمزها یکسان نیستند',
      'unfollow_q': 'دنبال کردن {u} لغو شود؟', 'unfollow': 'لغو دنبال کردن', 'profile_updated': 'پروفایل ذخیره شد', 'no_followers': 'هنوز دنبال‌کننده‌ای ندارد',
      'no_following': 'هنوز کسی را دنبال نمی‌کند', 'account': 'حساب کاربری', 'privacy': 'حریم خصوصی', 'preferences': 'ترجیحات',
    },
  };
}

class _Delegate extends LocalizationsDelegate<AppStrings> {
  const _Delegate();
  @override
  bool isSupported(Locale l) => ['en', 'fa'].contains(l.languageCode);
  @override
  Future<AppStrings> load(Locale l) => SynchronousFuture(AppStrings(l));
  @override
  bool shouldReload(_Delegate old) => false;
}

extension TrX on BuildContext {
  AppStrings get s => AppStrings.of(this);
  String t(String key) => AppStrings.of(this).get(key);
}
