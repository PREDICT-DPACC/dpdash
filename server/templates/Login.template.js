import basePathConfig from '../configs/basePathConfig';

const basePath = basePathConfig || '';

export default (message) => {
  const userState = {
    "message": message,
  };
  return `
		<!DOCTYPE html>
		<html>
			<head>
				<meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0">
				<title>DPdash</title>
				<link rel='stylesheet' href='${basePath}/css/login.css' />
			</head>
            <script>
                window.USER = ${JSON.stringify(userState)}
                window.SUBJECT = ${JSON.stringify(null)}
                window.GRAPH = ${JSON.stringify(null)}
            </script>
			<body>
				<div id = "main"></div>
				<script src="${basePath}/js/login.min.js">
				</script>
			</body>
		</html>
	`;
};
