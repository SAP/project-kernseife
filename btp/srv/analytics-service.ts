import { Service, log } from "@sap/cds";
import { Readable } from "stream";
import { getTotalScore } from "./features/developmentObject-feature";

export default (srv: Service) => {

    const LOG = log("AnalyticsService");


    srv.on('GET', 'Tiles', async (req: any) => {
        const tileType = req._.req.path.replace('/Tiles/', '');
        const mimetype = "text/plain";

        let content;
        switch (tileType) {
            case "totalScore":
                content = String(await getTotalScore())
                break;
            default:
                return req.error(400, `Tiles Type ${tileType} not found`);
        }
        req.reply(Readable.from([content]), { mimetype })
    });
};

