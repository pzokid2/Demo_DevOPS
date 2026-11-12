// security/rules/juice-shop-sqli.ts – file kiểm thử cho rule juice-shop-sqli-raw-query
// Chạy: semgrep --test security/rules/
// (thư mục security/ nằm ngoài tsconfig nên không bị biên dịch khi build image)
declare const models: any
declare const req: any

// ruleid: juice-shop-sqli-raw-query
models.sequelize.query(`SELECT * FROM Users WHERE email = '${req.body.email || ''}' AND deletedAt IS NULL`, { plain: true })

// ruleid: juice-shop-sqli-raw-query
models.sequelize.query("SELECT * FROM Users WHERE email = '" + req.body.email + "'")

// ok: juice-shop-sqli-raw-query
models.sequelize.query('SELECT * FROM Users WHERE email = :email AND deletedAt IS NULL', { replacements: { email: req.body.email || '' }, plain: true })
