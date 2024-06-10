#!/bin/bash
apt update
apt install -y apache2

# Get the instance ID using the instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Install the AWS CLI
apt install -y awscli

# Download the images from S3 bucket
#aws s3 cp s3://myterraformprojectbucket2023/project.webp /var/www/html/project.png --acl public-read


cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>

<head>
    <title>Live Flight Data Map</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <!-- Add references to the Azure Maps Map control JavaScript and CSS files. -->
    <link rel="stylesheet" href="https://atlas.microsoft.com/sdk/javascript/mapcontrol/2/atlas.min.css" type="text/css">
    <script src="https://atlas.microsoft.com/sdk/javascript/mapcontrol/2/atlas.min.js"></script>

    <!-- Add a reference to the Azure Maps Services Module JavaScript file. -->
    <script src="https://atlas.microsoft.com/sdk/javascript/mapcontrol/2/atlas-service.min.js"></script>

    <!-- Promis based http client. https://github.com/axios/axios -->
    <script src="https://unpkg.com/axios/dist/axios.min.js"></script>

    <script>
        //let flightDataUrl = 'http://localhost:7071/api/GetFlightData'
        let flightDataUrl = 'https://opensky-network.org/api/states/all?lamin=-50.00&lomin=160.00&lamax=-30.00&lomax=180.00';


        function GetMap() {
            //Instantiate a map object
            var map = new atlas.Map("myMap", {
                //Add your Azure Maps subscription key to the map SDK. Get an Azure Maps key at https://azure.com/maps
                authOptions: {
                    authType: 'subscriptionKey',
                    subscriptionKey: 'FjJgFf0Aw11FWSafn80u-jMb2OpAvZeLugHIo__AnBY'
                },
                style: "night",
                center: [172.00, -40.00],
                zoom: 6
            });

            //Wait until the map resources are ready.
            map.events.add('ready', function () {

                map.imageSprite.add('plane-icon', 'https://icones.pro/wp-content/uploads/2021/08/icone-d-avion-jaune.png');

                //Create a data source and add it to the map
                var datasource = new atlas.source.DataSource();
                map.sources.add(datasource);

                //Create a symbol layer using the data source and add it to the map
                map.layers.add(
                    new atlas.layer.SymbolLayer(datasource, null, {
                        iconOptions: {
                            ignorePlacement: true,
                            allowOverlap: true,
                            image: 'plane-icon',
                            size: 0.09,
                            rotation: ['get', 'rotation']
                        },
                        textOptions: {
                            textField: ['concat', ['to-string', ['get', 'name']], '- ', ['get', 'altitude']],
                            color: '#FFFFFF',
                            offset: [2, 0]
                        }
                    })
                );

                GetFlightData().then(function (response) {
                    for (var flight of response.data.states) {
                        var pin = new atlas.Shape(new atlas.data.Point([flight[5], flight[6]]));
                        pin.addProperty('name', flight[1]);
                        pin.addProperty('altitude', flight[7]);
                        pin.addProperty('rotation', flight[10]);
                        datasource.add(pin);
                    }
                });


            });
        }

        function GetFlightData() {
            return axios.get(flightDataUrl)
                .then(function (response) {
                    return response;
                }).catch(console.error)
        }
    </script>

    <style>
        html,
        body {
            width: 100%;
            height: 100%;
            padding: 0;
            margin: 0;
        }

        #myMap {
            width: 100%;
            height: 100%;
        }
    </style>
</head>

<body onload="GetMap()">
    <div id="myMap"></div>
</body>

</html>
EOF

# Start Apache and enable it on boot
systemctl start apache2
systemctl enable apache2