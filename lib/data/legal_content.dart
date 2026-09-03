class LegalBlock {
  final String type;
  final String text;
  final List<String> items;
  const LegalBlock(this.type, [this.text = '', this.items = const []]);
}

const privacyPolicyBlocks = <LegalBlock>[
LegalBlock('p', 'WORKER GIG BD (workergigbd.site) আপনার প্রাইভেসি সম্পর্কে গুরুত্বের সাথে আছে। এই পলিসি ব্যাখ্যা করে আমরা কী তথ্য সংগ্রহ করি, কীভাবে তা ব্যবহার করি এবং কীভাবে সুরক্ষিত রাখি।'),
LegalBlock('h2', '১. আমরা যে তথ্য সংগ্রহ করি'),
LegalBlock('ul', '', ['অ্যাকাউন্ট তথ্য: ইমেইল, ইউজারনেম, পাসওয়ার্ড (এনক্রিপ্টেড)।', 'প্রোফাইল তথ্য: ফোন নাম্বার, ফুল নেম, প্রোফাইল ছবি (যদি দিন)।', 'লেনদেন তথ্য: বিকাশ/নগদ/রকেট নাম্বার, ট্রানজেকশন আইডি, ডিপোজিট/উইথড্র রেকর্ড।', 'ব্যবহারের তথ্য: কুকিজ, লগ ডেটা, ডিভাইস ও ব্রাউজার তথ্য।']),
LegalBlock('h2', '২. তথ্য কীভাবে ব্যবহার হয়'),
LegalBlock('ul', '', ['অ্যাকাউন্ট তৈরি, পরিচয় প্রমাণ ও সেবা প্রদানের জন্য।', 'ডিপোজিট ও উইথড্র প্রসেস করার জন্য।', 'নোটিফিকেশন, আপডেট ও সাপোর্ট দেওয়ার জন্য।', 'প্রতারণা প্রতিরোধ ও নিরাপত্তা নিশ্চিত করার জন্য।']),
LegalBlock('h2', '৩. তথ্য সুরক্ষা'),
LegalBlock('p', 'আমরা শিল্প-মানের এনক্রিপশন (SSL/TLS) ও নিরাপদ ডেটাবেস ব্যবহার করি। শুধু অথেন্টিকেটেড অ্যাডমিনরা সংবেদনশীল তথ্য দেখতে পারে। তবে কোনো ইন্টারনেট ট্রান্সমিশন ১০০% নিরাপদ নয়।'),
LegalBlock('h2', '৪. কুকিজ'),
LegalBlock('p', 'আমরা সেশন ও ফাংশনাল কুকিজ ব্যবহার করি যাতে সাইট ঠিকমতো কাজ করে। অ্যানালিটিক্স কুকিজ (Google Analytics) আমরা ট্রাফিক বুঝতে ব্যবহার করতে পারি, যা আইপি অ্যানোনিমাইজড থাকে।'),
LegalBlock('h2', '৫. তৃতীয় পক্ষের সেবা'),
LegalBlock('p', 'আমরা Supabase (অথেন্টিকেশন/ডেটাবেস) এবং Vercel (হোস্টিং) ব্যবহার করি। পেমেন্ট প্রসেসিং সরাসরি বিকাশ/নগদ/রকেট-এর মাধ্যমে হয় — আমরা কার্ড বা ব্যাংক ডিটেইল সংরক্ষণ করি না।'),
LegalBlock('h2', '৬. আপনার অধিকার'),
LegalBlock('p', 'আপনি আপনার অ্যাকাউন্ট তথ্য দেখতে, আপডেট করতে বা মুছতে পারেন। ডেটা মুছে ফেলার অনুরোধ করতে সাপোর্ট টিকেট খুলুন।'),
LegalBlock('h2', '৭. যোগাযোগ'),
LegalBlock('p', 'যেকোনো প্রশ্নে wasimmostakim2965@gmail.com-এ ইমেইল করুন অথবা ড্যাশবোর্ড থেকে সাপোর্ট টিকেট খুলুন।'),
];

const termsBlocks = <LegalBlock>[
LegalBlock('p', 'WORKER GIG BD (workergigbd.site) ব্যবহার করে আপনি নিচের শর্তাবলিতে সম্মত হচ্ছেন। যদি আপনি এই শর্তে রাজি না হন, তাহলে সেবা ব্যবহার করবেন না।'),
LegalBlock('h2', '১. সেবার বিবরণ'),
LegalBlock('p', 'WORKER GIG BD একটি মাইক্রো-টাস্ক ও ফ্রিল্যান্স প্ল্যাটফর্ম যেখানে ইউজাররা অনলাইন টাস্ক সম্পন্ন করে আয় করতে পারেন এবং টাস্ক পোস্ট করতে পারেন। পেমেন্ট বিকাশ, নগদ ও রকেট-এর মাধ্যমে হয় (\$1 = 100 BDT)।'),
LegalBlock('h2', '২. অ্যাকাউন্ট'),
LegalBlock('ul', '', ['আপনার অ্যাকাউন্ট ও পাসওয়ার্ডের নিরাপত্তা আপনার দায়িত্ব।', 'সঠিক তথ্য দিতে হবে; মিথ্যা তথ্য অ্যাকাউন্ট সাসপেন্ড করার কারণ হতে পারে।', 'একজন ইউজার একাধিক অ্যাকাউন্ট খুলতে পারবেন না।']),
LegalBlock('h2', '৩. টাস্ক ও কাজ'),
LegalBlock('ul', '', ['কাজের প্রমাণ সঠিকভাবে জমা দিতে হবে; ভুয়া প্রমাণ নিষিদ্ধ।', 'প্রিমিয়াম কাজ শুধু প্রিমিয়াম ইউজারদের জন্য।', 'অ্যাডমিন যেকোনো কাজ বা টাস্ক প্রত্যাখ্যান বা মুছে ফেলার অধিকার রাখেন।']),
LegalBlock('h2', '৪. ডিপোজিট ও উইথড্র'),
LegalBlock('ul', '', ['ডিপোজিট অনুরোধ অ্যাডমিন ভেরিফাই করার পর ব্যালেন্সে যোগ হয়।', 'উইথড্র ন্যূনতম পরিমাণ পূরণ করতে হবে।', 'ভুয়া ট্রানজেকশন আইডি দিলে অ্যাকাউন্ট ব্লক হতে পারে।', 'ফি ও রেট অ্যাডমিন নির্ধারিত, পরিবর্তন হতে পারে।']),
LegalBlock('h2', '৫. নিষিদ্ধ কার্যকলাপ'),
LegalBlock('ul', '', ['বট, অটোমেশন বা প্রতারণামূলক পদ্ধতি নিষিদ্ধ।', 'অন্য ইউজারকে হয়রানি বা প্রতারণা করা যাবে না।', 'অবৈধ বা আপত্তিকর কনটেন্ট পোস্ট নিষিদ্ধ।']),
LegalBlock('h2', '৬. অ্যাকাউন্ট সাসপেনশন'),
LegalBlock('p', 'শর্ত ভঙ্গ করলে আমরা অ্যাকাউন্ট সাসপেন্ড বা ব্লক করতে পারি। সাসপেন্ডেড অ্যাকাউন্ট থেকে ব্যালেন্স দেখা যায় তবে কাজ বা উইথড্র বন্ধ থাকে।'),
LegalBlock('h2', '৭. দায়বদ্ধতার সীমা'),
LegalBlock('p', 'প্ল্যাটফর্ম "যেমন আছে" প্রদান করা হয়। আমরা কোনো আয়ের গ্যারান্টি দিই না। প্রযুক্তিগত ব্যর্থতা বা ডেটা ক্ষতির জন্য সর্বোচ্চ দায়বদ্ধতা সীমিত।'),
LegalBlock('h2', '৮. শর্তাবলির পরিবর্তন'),
LegalBlock('p', 'আমরা যেকোনো সময় এই শর্তাবলি আপডেট করতে পারি। আপডেটের পর সেবা ব্যবহার চালিয়ে গেলে আপনি নতুন শর্তে সম্মত বলে ধরা হবে।'),
LegalBlock('h2', '৯. যোগাযোগ'),
LegalBlock('p', 'প্রশ্নে wasimmostakim2965@gmail.com বা সাপোর্ট টিকেটের মাধ্যমে যোগাযোগ করুন।'),
];

const aboutBlocks = <LegalBlock>[
LegalBlock('h2', 'Our Mission'),
LegalBlock('p', 'WORKER GIG BD was built with one simple goal: to give every Bangladeshi with a smartphone and an internet connection a real, honest way to earn money online. Millions of people in Bangladesh want to work online but do not know where to start, and thousands of businesses need small digital tasks done quickly. We connect these two sides in one trusted marketplace.'),
LegalBlock('h2', 'What We Do'),
LegalBlock('p', 'We are a micro-job marketplace. Employers post small tasks — such as following a page, watching a video, installing an app, writing a short review, or testing a website — and set a reward for each completed task. Workers browse the marketplace, complete the tasks, submit proof (usually a screenshot), and get paid once the employer approves the work. From social media engagement to surveys and sign-ups, there are more than 45 categories of tasks available every day.'),
LegalBlock('h2', 'How Payments Work'),
LegalBlock('p', 'Trust is everything in online earning. That is why every employer must deposit funds into the platform before a job goes live, so the money for a task is already secured before a worker starts it. Workers can withdraw their earnings through bKash, Nagad, and Rocket — the mobile banking services Bangladeshis already use every day. Deposits and withdrawals are reviewed by our team to keep both sides safe.'),
LegalBlock('h2', 'Safety and Fairness'),
LegalBlock('p', 'We verify users, monitor task quality, and act on reports from both workers and employers. Duplicate or fake proof submissions are automatically detected, accounts that break the rules are suspended, and every payment leaves an auditable transaction record. Our support team is reachable through the in-platform ticket system and live chat, and you can always reach us through the details on our Contact page.'),
LegalBlock('h2', 'Who We Serve'),
LegalBlock('p', 'Whether you are a student looking for part-time income, a homemaker earning from your phone, or a business owner who needs a thousand real people to engage with your brand — WORKER GIG BD is built for you. We are proud to be a Bangladeshi platform, made for Bangladesh, and available nationwide.'),
LegalBlock('p', 'Have questions? Visit our Contact Us page, read the{\' \'} Terms of Service, or explore earning guides on our{\' \'} blog.'),
];
