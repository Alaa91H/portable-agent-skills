# Essential Agent Skills — العربية

<!-- i18n: lang=ar clusters=18 skills=79 -->

مجموعة منتقاة ومُتحقَّق منها من **79 مهارة للوكلاء** تغطي مسار العمل البرمجي
كاملًا: تحديد ما يُبنى، وبناؤه بأسلوب الاختبار أولًا، ومراجعته، وإطلاقه،
وتشغيله، وكتابة مهارات خاصة به.

كل مهارة تتبع مواصفة [Agent Skills](https://agentskills.io/specification)
المفتوحة، ويتحقق منها مدقّق داخل هذا المستودع، وتُنسخ إلى كل اصطلاحات اكتشاف
الوكلاء، لتعمل مع أي وكيل دون أي إعداد.

```sh
git clone https://github.com/Alaa91H/portable-agent-skills.git
cd portable-agent-skills && ./install.sh
```

> **ملاحظة عن الاتجاه:** هذه الوثيقة تُكتب من اليمين إلى اليسار، وجميع الأوامر
> واسماء المهارات تُركت بالإنجليزية عمدًا لأنها معرّفات لا تُترجَم.

## المحتوى

| | |
| --- | --- |
| المهارات | ٧٩، موزّعة على ١٨ مجالًا |
| الوكلاء | ١٤ وجهة تثبيت مُتحقَّق منها |
| الصيغة | Markdown خالص، بلا اعتماديات |
| الترخيص | MIT |

## المجالات

1. [Craft and process](https://agentskills.io) <!-- cluster: Craft and process -->
   تحديد ما يجب فعله، وتنفيذه بأسلوب الاختبار أولًا، وإثبات أنه يعمل.
2. [Testing and review](https://agentskills.io) <!-- cluster: Testing and review -->
   تمرير العمل للمراجعة، والتفاعل مع الملاحظات، وإثباته تحت الحمل.
3. [Working in a codebase](https://agentskills.io) <!-- cluster: Working in a codebase -->
   الاتجاه داخل الشيفرة، وتشغيلها، وإبقاؤها محدَّثة، والحفاظ على قابلية إدارتها.
4. [Version control](https://agentskills.io) <!-- cluster: Version control -->
   الفروع وworktree والدمج، والبنية الداخلية حين يفاجئك git.
5. [Interfaces and accessibility](https://agentskills.io) <!-- cluster: Interfaces and accessibility -->
   بناء الواجهات ومراجعتها، بما في ذلك التوطين والامتثال لـ WCAG.
6. [APIs and integrations](https://agentskills.io) <!-- cluster: APIs and integrations -->
   عقود HTTP وGraphQL، وإدارة الإصدارات، وwebhooks، والمصادقة، والدفع.
7. [Data and storage](https://agentskills.io) <!-- cluster: Data and storage -->
   الاستعلامات، وتغييرات المخطّط، والتخزين المؤقت، والمعالجة في الخلفية.
8. [Data engineering](https://agentskills.io) <!-- cluster: Data engineering -->
   نمذجة مستودع البيانات، وتنسيق المسارات، وضبط الحوسبة الموزّعة.
9. [Infrastructure and operations](https://agentskills.io) <!-- cluster: Infrastructure and operations -->
   الحاويات، والتنسيق، وشيفرة البنية التحتية، ومسارات CI، والخوادم والحوادث.
10. [Platform operations](https://agentskills.io) <!-- cluster: Platform operations -->
    وضع السحابة وتكلفتها، والأسرار والمفاتيح، وملاءمة البحث، وإطلاق التطبيقات المحمولة.
11. [Performance and observability](https://agentskills.io) <!-- cluster: Performance and observability -->
    إيجاد عنق الزجاجة، والتفكير في التزامن، ومعرفة إن كان النظام سليمًا.
12. [Reliability and lifecycle](https://agentskills.io) <!-- cluster: Reliability and lifecycle -->
    الإطلاق، والتعافي، والجدولة، والتعامل مع البيانات المحفوظة عن الأشخاص.
13. [Security](https://agentskills.io) <!-- cluster: Security -->
    إيجاد الثغرات القابلة للاستغلال في الشيفرة والاعتماديات وترويسات الاستجابة ومداخل الوكيل.
14. [LLM and agent engineering](https://agentskills.io) <!-- cluster: LLM and agent engineering -->
    البناء على النماذج اللغوية، وكتابة مهارات الوكلاء وتقديمها وتوزيعها.
15. [Cross-cutting correctness](https://agentskills.io) <!-- cluster: Cross-cutting correctness -->
    المجالات التي تختبئ فيها الأخطاء أكثر من غيرها: السجلّات والطوابع الزمنية.
16. [Checking your own work](https://agentskills.io) <!-- cluster: Checking your own work -->
    كتابة بوّابات تستطيع أن تفشل فعلًا، وأوامر shell التي تستند إليها بصمت.
17. [Working within an agent's limits](https://agentskills.io) <!-- cluster: Working within an agent's limits -->
    الاستفادة الجيدة من نافذة السياق، والنجاة من الضغط، وعدم تأكيد ما لم تتحقق منه.
18. [Producing trustworthy output](https://agentskills.io) <!-- cluster: Producing trustworthy output -->
    الميل الأخير: ما يدخل الإجابة، وكيف يُسنَد، وكيف تكتشف نصًّا توقّف عن العمل.

## التثبيت على وكيل محدّد

```sh
./install.sh claude --global     # Claude Code
./install.sh codex --global      # OpenAI Codex
./install.sh cursor --global     # Cursor
./install.sh --list              # عرض المعرّفات التسعة والسبعين
./install.sh --update            # جلب أحدث إصدار
```

## لماذا بقيت المهارات بالإنجليزية

يختار الوكيل المهارة بقراءة `name` و`description` فيها. إبقاء هذين الحقلين متطابقين
في كل اللغات هو ما يجعل المجموعة قابلة للتوجيه مهما كانت لغة الطلب. أمّا ما
تُرجم فعلًا فهو ما يحتاجه القارئ: الإطار، والتثبيت، ومحتوى كل مجال.

فهرس الترجمات ومصفوفة المنصّات:
[`docs/i18n/README.md`](README.md) و [`docs/platforms.md`](../platforms.md).