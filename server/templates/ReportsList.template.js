export default ({ uid, name, role, icon }) => {
  return `
		<!DOCTYPE html>
		<html>
			<head>
				<meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0">
        <link rel="stylesheet" href="/css/react-virtualized.css" />
        <link rel="stylesheet" href="/css/admin.css" />
				<title>Reports - DPdash</title>
				<script>
					window.USER = ${JSON.stringify({ uid, name, role, icon })}
					window.SUBJECT = ${JSON.stringify(null)}
					window.GRAPH = ${JSON.stringify(null)}
				</script>
			</head>
			<body>
				<div id="main"></div>
				<script src="/js/reportsList.min.js"></script>
			</body>
		</html>
	`;
};