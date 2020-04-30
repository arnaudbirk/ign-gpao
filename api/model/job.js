/**
 * @swagger
 * tags:
 *   name: jobs
 *   description: Manipulation des jobs
 */

/**
 * @swagger
 * paths:
 *   '/jobs':
 *     get:
 *       tags:
 *         - jobs
 *       summary: "Récupération de tous les jobs"
 *       description: "Récupération de tous les jobs quelque soit son status"
 *       responses:
 *         '200':
 *           description: OK
 *   '/job/ready':
 *     get:
 *       tags:
 *         - jobs
 *       summary: "Récupération de l'identifiant d'un job"
 *       description: "Récupération de l'identifiant d'un job avec le status ready et mise à jour de son à jour de son status en running"
 *       responses:
 *         '200':
 *           description: OK
 *   '/job/{id}/{status}':
 *     post:
 *       tags:
 *         - jobs
 *       summary: "Mise à jour d'un job"
 *       description: "Permet de mettre à jour le log et le statut d'un job en fonction de son identifiant"
 *       parameters:
 *         - in: path
 *           name: id
 *           description: l'identifiant du job à modfier
 *           required: true
 *           schema:
 *             type: integer
 *         - in: path
 *           name: status
 *           description: le statut du job à modifier
 *           required: true
 *           schema:
 *             type: string
 *             enum:
 *               - failed
 *               - done
 *         - in: path
 *           name: return_code
 *           description: le code de retour de la commande
 *           required: true
 *           schema:
 *             type: int
 *       requestBody:
 *         description: log en sortie du script
 *         required: true
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 log:
 *                   type: string
 *                 
 *       responses:
 *         '200':
 *           description: OK
 *   '/job':
 *     put:
 *       tags:
 *         - jobs
 *       summary: "Ajout d'un job"
 *       description: "Permet de un job à partir d'une ligne de commande"
 *       requestBody:
 *         description: ligne de commande a exécuter
 *         required: true
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 command:
 *                   type: string
 *                 name:
 *                   type: string
 *                 id_project:
 *                   type: integer
 *                 
 *       responses:
 *         '200':
 *           description: OK
 *   '/project':
 *     put:
 *       tags:
 *         - projects
 *       summary: "Ajout d'un projet"
 *       description: "Permet d ajout un projet avec ses differents jobs"
 *       requestBody:
 *         description: la structure du projet
 *         required: true
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 name:
 *                   type: string
 *                 
 *       responses:
 *         '200':
 *           description: OK
 */
