# appointment process

Appointment process for vfl

## how it works

TODO: document

## resources for squarespace site

*calendar embed*

```html
<iframe 
  src="https://calendar.google.com/calendar/embed?height=600&wkst=1&bgcolor=%234285F4&ctz=America%2FNew_York&mode=WEEK&showTabs=0&showPrint=0&showNav=1&title=VFL%20Lab&src=Y184aGZoYWpyZjRiOTVvMG05ZjZ0bTRtdnFsc0Bncm91cC5jYWxlbmRhci5nb29nbGUuY29t&src=Y19vazZkNnBqb3QzdnE1Zzk4ZTBoZTNiY2c0a0Bncm91cC5jYWxlbmRhci5nb29nbGUuY29t&src=Y181Y2Q5NHU2dDQzOWQ1YzF1Mjdyb29qNzFmY0Bncm91cC5jYWxlbmRhci5nb29nbGUuY29t&src=Y19ka25lb3Aybjg1ODJjamU5aGR1Ymx1Z3Yxc0Bncm91cC5jYWxlbmRhci5nb29nbGUuY29t&color=%2333B679&color=%23B39DDB&color=%234285F4&color=%23E67C73" 
  style="border-width:0" 
  width="100%" 
  height="450" 
  frameborder="0" 
  scrolling="no"
></iframe>
```

## jotform resources

*machine to url mapping*

Lab Access: Makerspace                                      vfl-makerspace-01
Lab Access: Woodshop                                        vfl-woodshop-01
3D Printer                                                  vfl-digifab-01
Laser Cutter (32"x20")                                      vfl-digifab-01
Laser Cutter (24"x18") - Recommend CUT ONLY                 vfl-digifab-01
Wide Format Vinyl Printer & Cutter (28.5" max wide)         vfl-print-01
Flatbed UV Printer (20"x13"x4")                             vfl-print-01
Shopbot CNC Router (96" x 48" x 4") CUT & ETCH              vfl-woodshop-01
Spray Booth (Respirator REQUIRED for paints & adhesives)    vfl-makerspace-01
Sewing Machine                                              vfl-makerspace-01
Embroidery Machine                                          vfl-digifab-01

## koalendar resources

webook link TODO:

### webhook

#### data

*scheduled*

```json
{
    "id": "Y5gwPUBeEkNActKw6nVib",
    "type": "event.created",
    "created_at": "2022-02-11T18:41:22Z",
    "invitee": {
        "name": "<username>",
        "email": "<username>@<domain>",
        "time_zone": "America/New_York",
        "fields": {}
    },
    "guests": [],
    "location": "VFL",
    "start_at": "2022-02-25T19:00:00Z",
    "end_at":"2022-02-25T1
```

*rescheduled*

```json
{
    "id": "d1U1WB5h31QdCtyA8I0bf",
    "type": "event.rescheduled",
    "created_at": "2022-02-11T18:56:31Z",
    "invitee": {
        "name": "<username>",
        "email": "<username>@<domain>",
        "time_zone": "America/New_York",
        "fields": {}
    },
    "guests": [],
    "location": "VFL",
    "start_at": "2022-02-25T20:00:00Z",
    "end_at": "2022-02-25T20:30:00Z",
    "link": {
        "id": "asd123",
        "slug": "catdog",
        "name": "CATDOG",
        "description": ""
    },
    "canceled_at": null,
    "cancel_reason": null
}
```

*canceled*

```json
{
    "id": "Y5gwPUBeEkNActKw6nVib",
    "type": "event.canceled",
    "created_at": "2022-02-11T18:41:23Z",
    "invitee": {
        "name": "<username>",
        "email": "<username>@<domain>",
        "time_zone": "America/New_York",
        "fields": []
    },
    "location": null,
    "start_at": "2022-02-25T19:00:00Z",
    "end_at": "2022-02-25T19:30:00Z",
    "link": {
        "id": "asd123",
        "slug": "catdog",
        "name": "CATDOG",
        "description": ""
    },
    "canceled_at": "2022-02-11T18:51:56Z",
    "cancel_reason": null
}
```

#### code

```javascript
`
This script runs every time this app's endpoint receives 
a http POST request. The requests come from koalendar.com,
the service the VFL uses to schedule appointments, every
time an appoinment is created, rescheduled, or canceled.

The script helps maintain the sheet so it accurately
reflects scheduling. This sheet is used as a db/table
for the VFL's check-in application. The student
must arrive within the time frame of the Start and 
End times.
`

const SHEET_NAME = "Spring 2022";
const ID_COLUMN = 5;

// -----> handle http post <-----

function doPost(e) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
  var data = JSON.parse(e.postData.contents);

  switch (data.type) {
    case "event.created":
        created(sheet, data);
        break;
    
    case "event.rescheduled":
        rescheduled(sheet, data);
        break;
    
    case "event.canceled":
      canceled(sheet, data);
      break;

    default:
        let msg = `unknown event type: <b>${data.type}<b><br><br>data:<br><br>${JSON.stringify(data)}`;
        handleError(msg);
        break;
  }
}

// -----> calendar helpers <-----

// NOTE: table order
// Name, Email, Start, End, Cal_ID

function created(sheet, data) {
  let toAppend = [
    data.invitee.name,
    data.invitee.email,
    data.start_at,
    data.end_at,
    data.id
  ];

  try {
    sheet.appendRow(toAppend);
  } catch (error) {
    let msg = `error adding event:<br><br><b>${error}<b><br><br>data:<br><br>${JSON.stringify(data)}`;
    handleError(msg);
  }
}

function rescheduled(sheet, data) {
  let toUpdate = [
    data.invitee.name,
    data.invitee.email,
    data.start_at,
    data.end_at,
    data.id
  ];

  try {
    idx = search(sheet, data.id);
    sheet.getRange(idx, 1, 1, 5).setValues([toUpdate]);
  } catch (error) {
    let msg = `error rescheduling event:<br><br><b>${error}<b><br><br>data:<br><br>${JSON.stringify(data)}`;
    handleError(msg);
  } 
}

function canceled(sheet, data) {
  try {
    idx = search(sheet, data.id)
    sheet.deleteRow(idx);
  } catch (error) {
    let msg = `error canceling event:<br><br><b>${error}<b><br><br>data:<br><br>${JSON.stringify(data)}`;
    handleError(msg);
  }  
}

function search(sheet, id) {
  let idRow;
  var ids = sheet.getRange(2, ID_COLUMN, sheet.getLastRow()).getValues();

  ids.forEach((idArr, idx) => {
    if (idArr[0] == id) {
      // idx starts at 1 and
      // first row is header
      idRow = idx + 2;
      return;
    }
  });

  return idRow;
}

// -----> error <-----

function handleError(msg) {
  MailApp.sendEmail({
     to: "<email>@<domain>",
     subject: "|-----> CALENDAR SHEET ISSUE <-----|",
     htmlBody: "AHHH... <br><br>" + msg
  });
}
```